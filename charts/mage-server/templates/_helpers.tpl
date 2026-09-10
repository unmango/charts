{{/* vim: set filetype=mustache: */}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) }}
{{- end -}}

{{/*
Name of the Secret holding the mail credentials.
*/}}
{{- define "secretName" -}}
{{- if .Values.mail.existingSecret -}}
    {{- .Values.mail.existingSecret -}}
{{- else -}}
    {{ printf "%s-mail" .Release.Name }}
{{- end -}}
{{- end -}}

{{/*
Whether the chart renders a mail Secret of its own.
*/}}
{{- define "manageSecret" -}}
{{- if and (not .Values.mail.existingSecret) (or .Values.mail.password .Values.mail.mailgunApiKey) -}}
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

{{/*
The full recommended label set, for object and pod metadata.
*/}}
{{- define "labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
