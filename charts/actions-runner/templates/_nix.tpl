{{/* vim: set filetype=mustache: */}}

{{/*
Pod spec fragments for a runner that builds with Nix.

Every template takes the `nix` block itself as its argument rather than reading
`.Values`, so a consumer can keep the block wherever it likes:

    {{ include "actions-runner.nix.volume" .Values.nix }}

The block is documented in charts/gha-runner-scale-set/values.yaml, which is the reference
consumer. Templates render nothing at all when `enabled` is false, so a caller
can splice them in unconditionally.
*/}}

{{/*
Name of the volume carrying the store. Both the volume and the mount read it, so
they cannot drift.
*/}}
{{- define "actions-runner.nix.volumeName" -}}
{{- default "nix" (dig "store" "volumeName" "" .) -}}
{{- end -}}

{{/*
The store's mount path, and deliberately not configurable.

nix compiles /nix/store in, and `store = local` does not follow a volume
somewhere else; pointing it at another path takes a second setting and yields a
store no substituter can serve, so every dependency would be built from source.
Mounting anywhere but /nix would therefore look like it worked and quietly leave
the runner building on the container filesystem.
*/}}
{{- define "actions-runner.nix.mountPath" -}}
/nix
{{- end -}}

{{/*
nix.conf-format text for NIX_CONFIG.

Order is deliberate: nix takes the last assignment of a key, so the computed
settings come first and `conf` then `extraConf` can override them. The
substituter lists render as `extra-` forms, which append to the image's rather
than replacing them, this being the mistake that otherwise costs a consumer
cache.nixos.org.
*/}}
{{- define "actions-runner.nix.config" -}}
{{- with .substituters }}
extra-substituters = {{ join " " . }}
{{- end }}
{{- with .trustedPublicKeys }}
extra-trusted-public-keys = {{ join " " . }}
{{- end }}
{{- /*
  max-jobs is nix's default of 1, so a runner builds one derivation at a time
  whatever the pod is given. `auto` is not the fix: nix reads the machine's core
  count rather than the cgroup's CPU limit, so a pod limited to 2 cores on a 24
  core node resolves it to 24. cores, which a builder gets as -j, defaults to 0
  and means the same thing. Both are left to the consumer, who is the only one
  who knows what the pod is allowed.
*/}}
{{- with .maxJobs }}
max-jobs = {{ . }}
{{- end }}
{{- with .cores }}
cores = {{ . }}
{{- end }}
{{- /*
  Collection is correct only for a store that outlives the pod. nix collects
  mid-build, whenever free space falls under min-free, until max-free is
  available again.
*/}}
{{- with (dig "gc" "minFree" "" .) }}
min-free = {{ . }}
{{- end }}
{{- with (dig "gc" "maxFree" "" .) }}
max-free = {{ . }}
{{- end }}
{{- range $k, $v := .conf }}
{{ $k }} = {{ $v }}
{{- end }}
{{- with .extraConf }}
{{ . | trimSuffix "\n" }}
{{- end }}
{{- end -}}

{{/*
The NIX_CONFIG env entry, as a list item.

NIX_CONFIG rather than a ConfigMap over /etc/nix/nix.conf, because nix merges
the variable on top of that file while a mount replaces it, taking the image's
`store = local` and `experimental-features` with it.

Renders nothing when the assembled config is empty, so a runner with no settings
does not carry an empty variable.
*/}}
{{- define "actions-runner.nix.env" -}}
{{- if .enabled }}
{{- $config := include "actions-runner.nix.config" . | trim }}
{{- with $config }}
- name: NIX_CONFIG
  value: |
    {{- . | nindent 4 }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
The store volume, as a list item.

An emptyDir is the default worth reaching for. Kubelet creates one mode 0777 and
nix creates store, var and its build directory with its own modes rather than
the volume's, so it needs neither an fsGroup nor an initContainer to prepare it.

A store on the container filesystem, which is what `none` leaves, is an
overlayfs, where nix cannot tear down a build directory it has just emptied and
fails with `cannot unlink ...: Directory not empty`. Derivations that write many
small files hit it reliably.
*/}}
{{- define "actions-runner.nix.volume" -}}
{{- if .enabled }}
{{- $store := default (dict) .store }}
{{- $backing := default "emptyDir" $store.backing }}
{{- $name := include "actions-runner.nix.volumeName" . }}
{{- if eq $backing "emptyDir" }}
- name: {{ $name }}
  emptyDir: {{ default (dict) $store.emptyDir | toYaml | nindent 4 }}
{{- else if eq $backing "ephemeral" }}
{{- $claim := default (dict) $store.ephemeral }}
- name: {{ $name }}
  ephemeral:
    volumeClaimTemplate:
      spec:
        accessModes: {{ default (list "ReadWriteOnce") $claim.accessModes | toYaml | nindent 10 }}
        {{- with $claim.storageClassName }}
        storageClassName: {{ . }}
        {{- end }}
        resources:
          requests:
            storage: {{ required "nix.store.ephemeral.size is required when nix.store.backing is ephemeral" $claim.size }}
{{- else if eq $backing "existingClaim" }}
- name: {{ $name }}
  persistentVolumeClaim:
    claimName: {{ required "nix.store.existingClaim is required when nix.store.backing is existingClaim" $store.existingClaim }}
{{- else if eq $backing "hostPath" }}
{{- $host := default (dict) $store.hostPath }}
- name: {{ $name }}
  hostPath:
    path: {{ required "nix.store.hostPath.path is required when nix.store.backing is hostPath" $host.path }}
    type: {{ default "DirectoryOrCreate" $host.type }}
{{- else if ne $backing "none" }}
{{- fail (printf "nix.store.backing must be one of emptyDir, ephemeral, existingClaim, hostPath, none; got %q" $backing) }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
The store's volumeMount, as a list item. Empty when the store has no volume of
its own, so it pairs with actions-runner.nix.volume.
*/}}
{{- define "actions-runner.nix.volumeMount" -}}
{{- if .enabled }}
{{- if ne (default "emptyDir" (dig "store" "backing" "emptyDir" .)) "none" }}
- name: {{ include "actions-runner.nix.volumeName" . }}
  mountPath: {{ include "actions-runner.nix.mountPath" . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
The gid that must own a claim-backed store, which is the runner user's in the
image this chart is built around.
*/}}
{{- define "actions-runner.nix.fsGroup" -}}
{{- default 1001 (dig "store" "fsGroup" 1001 .) -}}
{{- end -}}

{{/*
Non-empty when the store is backed by a claim, which arrives owned by root and
so needs an fsGroup to be writable by the runner. An emptyDir does not, kubelet
creating it world-writable, and a hostPath's ownership is the node's business.
*/}}
{{- define "actions-runner.nix.needsFsGroup" -}}
{{- if .enabled }}
{{- $backing := default "emptyDir" (dig "store" "backing" "emptyDir" .) }}
{{- if or (eq $backing "ephemeral") (eq $backing "existingClaim") }}
true
{{- end }}
{{- end }}
{{- end -}}
