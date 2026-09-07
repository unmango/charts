{{/*
Namespace for one entry.

Rendered from .Values.namespaceTemplate against the entry, so `{{ .name }}` is
the entry's name. The context is the entry plus Release and Chart; .Files and
.Capabilities are not available there.

An empty namespaceTemplate puts every entry in the release namespace, which is
what a distinct runnerScaleSetName per entry allows. Setting it gives each entry
a namespace of its own, which is what sharing one runnerScaleSetName requires.

The substitutions exist because a repo name carries characters a namespace
cannot: `thecluster.io` and `unstoppablemango.io` are valid entry names and
invalid namespaces.
*/}}
{{- define "gha-runner-scale-sets.namespace" -}}
{{- $t := .root.Values.namespaceTemplate -}}
{{- if $t -}}
{{- $ctx := merge (dict "Release" .root.Release "Chart" .root.Chart) .entry -}}
{{- tpl $t $ctx | lower | replace "." "-" | replace "_" "-" | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- .root.Release.Namespace -}}
{{- end -}}
{{- end }}
