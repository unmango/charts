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
Number of tasks the agent runs at once. The agent's "auto" counts the
host's CPUs rather than the pod's cgroup quota, so on a large node it claims
far more tasks than the pod can run, and every one of them crawls. Resolve
"auto" against the pod's CPU budget instead, preferring the limit that sets
the quota and falling back to the request. The floor is two tasks, matching
the agent's own "auto", because import-from-derivation deadlocks with one.
An explicit number, or "auto" with no budget set, is passed through.
*/}}
{{- define "concurrentTasks" -}}
{{- $tasks := .Values.agent.concurrentTasks -}}
{{- if kindIs "invalid" $tasks -}}
{{- $tasks = "auto" -}}
{{- end -}}
{{- $cpu := dig "limits" "cpu" (dig "requests" "cpu" "" .Values.resources) .Values.resources -}}
{{- if and (eq (toString $tasks) "auto") $cpu -}}
{{- $cores := toString $cpu -}}
{{- if hasSuffix "m" $cores -}}
{{- $cores = divf (float64 (trimSuffix "m" $cores)) 1000.0 -}}
{{- else -}}
{{- $cores = float64 $cores -}}
{{- end -}}
{{- max 2 (floor $cores) -}}
{{- else -}}
{{- $tasks -}}
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
