{{/* vim: set filetype=mustache: */}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "chart" .Chart) }}
{{- end -}}

{{- define "mongodb.image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.mongodb.image "global" .Values.global) }}
{{- end -}}

{{- define "mongodb.name" -}}
{{ printf "%s-mongodb" .Release.Name }}
{{- end -}}

{{- define "mongodb.host" -}}
{{- if .Values.mongodb.enabled -}}
    {{ include "mongodb.name" . }}
{{- else -}}
    {{ required "database.host is required when mongodb.enabled is false" .Values.database.host }}
{{- end -}}
{{- end -}}

{{/*
JVM flags pointing at the mounted truststore. They go through
JAVA_TOOL_OPTIONS, which every JVM reads on its own, because the image offers
no way to pass options to the controller.
*/}}
{{- define "truststore.javaOptions" -}}
{{- $opts := list
    (printf "-Djavax.net.ssl.trustStore=/truststore/%s" .Values.truststore.key)
    "-Djavax.net.ssl.trustStoreType=PKCS12" -}}
{{- with .Values.truststore.password -}}
    {{- $opts = append $opts (printf "-Djavax.net.ssl.trustStorePassword=%s" .) -}}
{{- end -}}
{{ join " " $opts }}
{{- end -}}

{{/*
Name of the Secret holding the MongoDB passwords.
*/}}
{{- define "secretName" -}}
{{- if .Values.database.existingSecret -}}
    {{- .Values.database.existingSecret -}}
{{- else -}}
    {{ include "mongodb.name" . }}
{{- end -}}
{{- end -}}

{{/*
A password from values, else the one already in the chart-managed Secret, else
a new random one. Reusing the stored value keeps upgrades from rotating a
password MongoDB has already been initialised with.
Takes a dict with the root context as "ctx", the Secret key as "key", and the
value as "value".
*/}}
{{- define "password" -}}
{{- if .value -}}
    {{- .value -}}
{{- else -}}
    {{- $secret := lookup "v1" "Secret" .ctx.Release.Namespace (include "mongodb.name" .ctx) -}}
    {{- if and $secret (hasKey $secret.data .key) -}}
        {{- index $secret.data .key | b64dec -}}
    {{- else -}}
        {{- randAlphaNum 32 -}}
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
