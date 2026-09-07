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
The agent reads three files from one directory, assembled by a projected
volume. Two sources claiming the same path is a kubelet error, so each file
gets exactly one source: existingSecret owns every secret file, and the chart
owns them only in its absence.
*/}}
{{- define "validateSecrets" -}}
{{- if .Values.existingSecret -}}
{{- if .Values.clusterJoinToken -}}
{{- fail "clusterJoinToken conflicts with existingSecret: put the token in that Secret under existingSecretKey" -}}
{{- end -}}
{{- if .Values.secretsJson -}}
{{- fail "secretsJson conflicts with existingSecret: put secrets.json in that Secret" -}}
{{- end -}}
{{- else if not .Values.clusterJoinToken -}}
{{- fail "set existingSecret to a Secret holding the cluster join token, or clusterJoinToken to have the chart render one" -}}
{{- end -}}
{{- range $name, $cache := .Values.binaryCaches -}}
{{- if kindIs "map" $cache -}}
{{- if or (hasKey $cache "authToken") (get $cache "signingKeys") -}}
{{- fail (printf "binaryCaches.%s carries credentials, and binaryCaches is rendered into a ConfigMap: leave it empty and supply binary-caches.json through existingSecret" $name) -}}
{{- end -}}
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

{{- define "labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{ include "selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
