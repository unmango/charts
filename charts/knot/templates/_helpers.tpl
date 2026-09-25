{{/* vim: set filetype=mustache: */}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) }}
{{- end -}}

{{- define "hostname" -}}
{{ required "hostname is required" .Values.hostname }}
{{- end -}}

{{/*
Name of the Secret holding the master key.
*/}}
{{- define "masterKey.secretName" -}}
{{- if .Values.masterKey.existingSecret -}}
    {{- .Values.masterKey.existingSecret -}}
{{- else -}}
    {{ printf "%s-master-key" .Release.Name }}
{{- end -}}
{{- end -}}

{{/*
The master key from values, else the one already in the chart-managed Secret,
else 32 new random bytes. Reusing the stored value keeps an upgrade from
replacing the key the sealed store was written with. An upgrade that cannot
read the Secret fails rather than generating a new key.
*/}}
{{- define "masterKey.value" -}}
{{- if .Values.masterKey.value -}}
    {{- .Values.masterKey.value -}}
{{- else -}}
    {{- $secret := lookup "v1" "Secret" .Release.Namespace (include "masterKey.secretName" .) -}}
    {{- if and $secret (hasKey $secret.data .Values.masterKey.key) -}}
        {{- index $secret.data .Values.masterKey.key | b64dec -}}
    {{- else if .Release.IsUpgrade -}}
        {{- fail "masterKey: the existing Secret could not be read; set masterKey.value or masterKey.existingSecret instead of generating a new key" -}}
    {{- else -}}
        {{- randBytes 32 -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Labels that identify the release. Selectors are immutable, so these must not
include anything that changes between versions.
*/}}
{{- define "selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
The full recommended label set, for object and pod metadata.
*/}}
{{- define "labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
