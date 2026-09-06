{{/* vim: set filetype=mustache: */}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "defaultVersion" .Chart.AppVersion) }}
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
Return the proper image name
{{ include "common.images.image" ( dict "imageRoot" .Values.path.to.the.image "global" .Values.global "defaultVersion" .Chart.AppVersion ) }}
*/}}
{{/*
https://github.com/bitnami/charts/blob/74e1f3fcbe3c1848895df175557f83a53f9cdffc/bitnami/common/templates/_images.tpl#L7-L30
*/}}
{{- define "common.images.image" -}}
{{- $registryName := .imageRoot.registry -}}
{{- $repositoryName := .imageRoot.repository -}}
{{- $separator := ":" -}}
{{- $termination := .imageRoot.tag | default .defaultVersion | toString -}}
{{- if .global }}
    {{- if .global.imageRegistry }}
     {{- $registryName = .global.imageRegistry -}}
    {{- end -}}
{{- end -}}
{{- if .imageRoot.digest }}
    {{- $separator = "@" -}}
    {{- $termination = .imageRoot.digest | toString -}}
{{- end -}}
{{- if $registryName }}
    {{- printf "%s/%s%s%s" $registryName $repositoryName $separator $termination -}}
{{- else -}}
    {{- printf "%s%s%s"  $repositoryName $separator $termination -}}
{{- end -}}
{{- end -}}
