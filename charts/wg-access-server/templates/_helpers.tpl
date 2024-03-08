{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "wg-access-server.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "wg-access-server.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "wg-access-server.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "wg-access-server.labels" -}}
helm.sh/chart: {{ include "wg-access-server.chart" . }}
{{ include "wg-access-server.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "wg-access-server.selectorLabels" -}}
app: {{ include "wg-access-server.name" . }}
app.kubernetes.io/name: {{ include "wg-access-server.name" . }}
app.kubernetes.io/instance: {{ include "wg-access-server.name" . }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "wg-access-server.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "wg-access-server.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create a randomly generated admin password if none is supplied
*/}}
{{- define "wg-access-server.adminPassword" -}}
{{- if .Values.web.config.adminPassword -}}
    {{ .Values.web.config.adminPassword }}
{{- else -}}
{{- $secret := (lookup "v1" "Secret" .Release.Namespace (include "wg-access-server.fullname" .)) -}}
{{- if $secret -}}
    {{-  $secret.data.adminPassword | b64dec -}}
{{- else -}}
    {{- randAlphaNum 20 -}}
{{- end -}}
{{- end -}}
{{- end -}}


{{/*
Return PostgreSQL Connection Secret Name
*/}}
{{- define "wg-access-server.storageConnectionSecretName" -}}
{{- if .Values.storage.existingSecret -}}
    {{- .Values.storage.existingSecret -}}
{{- else -}}
    {{- include "wg-access-server.name" . -}}
{{- end -}}
{{- end -}}


{{/*
Return Web Config Secret Name
*/}}
{{- define "wg-access-server.webConfigSecretName" -}}
{{- if .Values.web.config.existingSecret -}}
    {{- .Values.web.config.existingSecret -}}
{{- else -}}
    {{- include "wg-access-server.name" . -}}
{{- end -}}
{{- end -}}


{{/*
Return WireGuard Config Secret Name
*/}}
{{- define "wg-access-server.wireguardConfigSecretName" -}}
{{- if .Values.wireguard.config.existingSecret -}}
    {{- .Values.wireguard.config.existingSecret -}}
{{- else -}}
    {{- include "wg-access-server.name" . -}}
{{- end -}}
{{- end -}}


{{/*
Return WireGuard secretConfig Secret Name
*/}}
{{- define "wg-access-server.secretConfigSecretName" -}}
{{- if .Values.secretConfig.existingSecret -}}
    {{- .Values.secretConfig.existingSecret -}}
{{- else -}}
    {{- include "wg-access-server.name" . -}}
{{- end -}}
{{- end -}}
