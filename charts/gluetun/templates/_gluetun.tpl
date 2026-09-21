{{/* vim: set filetype=mustache: */}}

{{/*
Pod spec fragments that put a gluetun sidecar in front of a workload.

Every template takes a dict with the consumer's `gluetun` block as "gluetun",
and gluetun.initContainers also takes "inputPorts", the container ports the
firewall must admit. The defaults live in this chart's values.yaml, which Helm
merges into the consumer under `.Values.gluetun`. Templates render nothing when
`enabled` is false, so a caller can splice them in unconditionally.
*/}}

{{- define "gluetun.image" -}}
{{- $ref := printf "%s/%s" .registry .repository -}}
{{- if .digest -}}
{{- printf "%s@%s" $ref .digest -}}
{{- else -}}
{{- printf "%s:%s" $ref .tag -}}
{{- end -}}
{{- end -}}

{{- define "gluetun.volumeName" -}}
gluetun-wireguard
{{- end -}}

{{/*
List items for the pod's initContainers: the PIA config generator when
pia.enabled, then gluetun as a native sidecar, so it starts before and stops
after the workload's containers.
*/}}
{{- define "gluetun.initContainers" -}}
{{- $g := .gluetun -}}
{{- if $g.enabled }}
{{- $ports := concat (.inputPorts | default list) ($g.firewall.inputPorts | default list) | uniq -}}
{{- if $g.pia.enabled }}
- name: pia-config
  image: {{ include "gluetun.image" $g.pia.image }}
  env:
    - name: PIA_USER
      valueFrom:
        secretKeyRef:
          name: {{ required "gluetun.pia.existingSecret is required when gluetun.pia.enabled is true" $g.pia.existingSecret }}
          key: {{ $g.pia.usernameKey }}
    - name: PIA_PASS
      valueFrom:
        secretKeyRef:
          name: {{ $g.pia.existingSecret }}
          key: {{ $g.pia.passwordKey }}
    - name: VPN_PROTOCOL
      value: wireguard
    # Writes the config and exits rather than bringing the tunnel up itself;
    # gluetun owns the connection.
    - name: PIA_CONNECT
      value: "false"
    - name: PIA_CONF_PATH
      value: /vpn/wg0.conf
    - name: AUTOCONNECT
      value: "true"
    - name: DISABLE_IPV6
      value: "yes"
    - name: PIA_DNS
      value: "false"
    - name: PIA_PF
      value: "false"
  {{- with $g.pia.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  volumeMounts:
    - name: {{ include "gluetun.volumeName" . }}
      mountPath: /vpn
{{- end }}
- name: gluetun
  image: {{ include "gluetun.image" $g.image }}
  restartPolicy: Always
  securityContext:
    capabilities:
      add:
        - NET_ADMIN
  env:
    {{- if $g.pia.enabled }}
    - name: VPN_SERVICE_PROVIDER
      value: custom
    {{- end }}
    - name: VPN_TYPE
      value: {{ $g.vpnType | quote }}
    {{- with $g.firewall.outboundSubnets }}
    - name: FIREWALL_OUTBOUND_SUBNETS
      value: {{ join "," . | quote }}
    {{- end }}
    {{- with $ports }}
    - name: FIREWALL_INPUT_PORTS
      value: {{ join "," . | quote }}
    {{- end }}
    {{- with $g.env }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $g.resources }}
  resources:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $g.startupProbe }}
  startupProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $g.livenessProbe }}
  livenessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  {{- with $g.readinessProbe }}
  readinessProbe:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  # Removes the policy rule that would send pod-to-pod traffic into the tunnel.
  # https://github.com/qdm12/gluetun-wiki/blob/main/setup/advanced/kubernetes.md
  lifecycle:
    postStart:
      exec:
        command:
          - /bin/sh
          - -c
          - (ip rule del table 51820 2>/dev/null; ip -6 rule del table 51820 2>/dev/null) || true
  {{- if $g.pia.enabled }}
  volumeMounts:
    - name: {{ include "gluetun.volumeName" . }}
      mountPath: /gluetun/wireguard
  {{- end }}
{{- end }}
{{- end -}}

{{/*
List items for the pod's volumes.
*/}}
{{- define "gluetun.volumes" -}}
{{- if and .gluetun.enabled .gluetun.pia.enabled }}
- name: {{ include "gluetun.volumeName" . }}
  emptyDir: {}
{{- end }}
{{- end -}}

{{/*
The pod's dnsConfig mapping body, empty when disabled.
*/}}
{{- define "gluetun.dnsConfig" -}}
{{- if .gluetun.enabled }}
{{- with .gluetun.dnsConfig }}
{{- toYaml . }}
{{- end }}
{{- end }}
{{- end -}}

{{/*
Whether the pod has any volume or init container from this chart, so a
consumer can decide whether to open the list keys at all.
*/}}
{{- define "gluetun.hasVolumes" -}}
{{- if and .gluetun.enabled .gluetun.pia.enabled }}true{{ end }}
{{- end -}}
