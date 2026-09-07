{{/* vim: set filetype=mustache: */}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) }}
{{- end -}}

{{/*
Name of the chart-owned Secret. Only rendered for the clusterJoinToken and
secretsJson escape hatch; the supported path is existingSecret.
*/}}
{{- define "secretName" -}}
{{ printf "%s-agent-secrets" .Release.Name }}
{{- end -}}

{{/*
Non-empty when the escape hatch put something in the chart-owned Secret.
clusterJoinToken is ignored when existingSecret supplies the token.
*/}}
{{- define "renderSecret" -}}
{{- if or (and .Values.clusterJoinToken (not .Values.existingSecret)) .Values.secretsJson -}}
true
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

{{- define "labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
