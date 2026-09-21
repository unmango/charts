{{/* vim: set filetype=mustache: */}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) }}
{{- end -}}

{{- define "auth.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.auth.image "global" .Values.global) }}
{{- end -}}

{{/*
Name of the Secret holding the WebUI password, empty when none is configured.
*/}}
{{- define "secretName" -}}
{{- if .Values.auth.existingSecret -}}
    {{- .Values.auth.existingSecret -}}
{{- else if .Values.auth.password -}}
    {{ .Release.Name }}
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
