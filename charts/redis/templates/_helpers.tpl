{{/* vim: set filetype=mustache: */}}

{{- define "image" -}}
{{ include "common.images.image" (dict "imageRoot" .Values.image "global" .Values.global "defaultVersion" .Chart.AppVersion) }}
{{- end -}}

{{/*
Name of the Secret holding the redis password.
*/}}
{{- define "secretName" -}}
{{- if .Values.auth.existingSecret -}}
    {{- .Values.auth.existingSecret -}}
{{- else -}}
    {{ printf "%s-auth" .Release.Name }}
{{- end -}}
{{- end -}}

{{/*
Whether the chart renders a password Secret of its own.
*/}}
{{- define "manageSecret" -}}
{{- if and .Values.auth.enabled (not .Values.auth.existingSecret) -}}
true
{{- end -}}
{{- end -}}

{{/*
Name of the headless Service backing the StatefulSet. Cluster nodes gossip
over stable pod DNS, which only a headless Service provides.
*/}}
{{- define "headlessServiceName" -}}
{{ printf "%s-headless" .Release.Name }}
{{- end -}}

{{/*
Pod count. A cluster needs one pod per master plus its replicas; a standalone
release is just replicaCount.
*/}}
{{- define "replicas" -}}
{{- if .Values.cluster.enabled -}}
{{- mul .Values.cluster.shards (add1 .Values.cluster.replicasPerShard) -}}
{{- else -}}
{{- .Values.replicaCount -}}
{{- end -}}
{{- end -}}

{{/*
Space separated <pod-dns>:<port> for every pod, in ordinal order. valkey-cli
--cluster create assigns the first `shards` entries as masters.
*/}}
{{- define "nodeAddresses" -}}
{{- $root := . -}}
{{- $addrs := list -}}
{{- range $i := until (int (include "replicas" .)) -}}
{{- $addrs = append $addrs (printf "%s-%d.%s.%s.svc.%s:%d" $root.Release.Name $i (include "headlessServiceName" $root) $root.Release.Namespace $root.Values.clusterDomain (int $root.Values.service.port)) -}}
{{- end -}}
{{- join " " $addrs -}}
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
