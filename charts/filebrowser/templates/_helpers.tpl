{{/* vim: set filetype=mustache: */}}

{{- define "configMapName" -}}
{{- if .Values.existingConfigMap -}}
    {{- include .Values.existingConfigMap . -}}
{{- else -}}
    {{ printf "%s-config" .Release.Name }}
{{- end -}}
{{- end -}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) }}
{{- end -}}

{{- define "init.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.init.image "global" .Values.global "chart" .Chart) }}
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
