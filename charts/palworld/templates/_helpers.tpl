{{/* vim: set filetype=mustache: */}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) }}
{{- end -}}

{{- define "saveRamdisk.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.saveRamdisk.image "global" .Values.global) }}
{{- end -}}

{{/*
Name of the Secret holding the server passwords.
*/}}
{{- define "secretName" -}}
{{- if .Values.auth.existingSecret -}}
    {{- .Values.auth.existingSecret -}}
{{- else -}}
    {{ .Release.Name }}
{{- end -}}
{{- end -}}

{{/*
The admin password from values, else the one already in the chart-managed
Secret, else a new random one, so upgrades do not rotate it.
*/}}
{{- define "adminPassword" -}}
{{- if .Values.auth.adminPassword -}}
    {{- .Values.auth.adminPassword -}}
{{- else -}}
    {{- $secret := lookup "v1" "Secret" .Release.Namespace (include "secretName" .) -}}
    {{- if and $secret (hasKey $secret.data .Values.auth.adminPasswordKey) -}}
        {{- index $secret.data .Values.auth.adminPasswordKey | b64dec -}}
    {{- else -}}
        {{- randAlphaNum 32 -}}
    {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Pal/Saved inside the claim, where saveRamdisk mirrors the live save.
*/}}
{{- define "saveRamdisk.mirrorPath" -}}
{{- if .Values.persistence.subPath -}}
    {{ printf "%s/Pal/Saved" (trimSuffix "/" .Values.persistence.subPath) }}
{{- else -}}
    Pal/Saved
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
