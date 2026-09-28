{{/*
Expand the name of the chart.
*/}}
{{- define "media-servarr-base.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "media-servarr-base.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "media-servarr-base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "media-servarr-base.labels" -}}
helm.sh/chart: {{ include "media-servarr-base.chart" . | quote }}
{{ include "media-servarr-base.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "media-servarr-base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "media-servarr-base.name" . | quote }}
app.kubernetes.io/instance: {{ .Release.Name | quote }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "media-servarr-base.serviceAccountName" -}}
{{- if .Values.serviceAccount }}
  {{- if .Values.serviceAccount.create }}
{{- default (include "media-servarr-base.fullname" .) .Values.serviceAccount.name }}
  {{- else }}
    {{- default "default" .Values.serviceAccount.name }}
  {{- end }}
{{- else -}}
default
{{- end }}
{{- end }}

{{/*
Merge global, default, values, and custom values
*/}}
{{- define "media-servarr-base.prepareValues" -}}
{{- /* Access the subchart values using index for keys with dashes */ -}}
{{- $subchartValues := index .Subcharts "media-servarr-base" -}}

{{- /* Merge custom values into .Values */ -}}
{{- /* Ensure that the subchart values are being accessed correctly */ -}}
{{- $mergedValues := merge .Values $subchartValues.Values -}}

{{- /* Set the merged values as a global variable */ -}}
{{- /* Use set to modify the scope variable */ -}}
{{- $_ := set $ "Values" $mergedValues -}}
{{- end }}

{{/*
Main templator function
Use all default templates and logic
*/}}
{{- define "media-servarr-base.template" -}}
{{ include "media-servarr-base.deployment" . }}
{{ include "media-servarr-base.statefulset" . }}
{{ include "media-servarr-base.service" . }}
{{ include "media-servarr-base.service-headless" . }}
{{ include "media-servarr-base.configmap" . }}
{{ include "media-servarr-base.secret" . }}
{{ include "media-servarr-base.serviceaccount" . }}
{{ include "media-servarr-base.servicemonitor" . }}
{{ include "media-servarr-base.ingress" . }}
{{ include "media-servarr-base.persistentvolumeclaim" . }}
{{- end }}
