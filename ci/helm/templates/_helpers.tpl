{{/*
Expand the name of the chart.
*/}}
{{- define "sample-a.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "sample-a.fullname" -}}
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
{{- define "sample-a.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "sample-a.labels" -}}
helm.sh/chart: {{ include "sample-a.chart" . }}
{{ include "sample-a.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "sample-a.selectorLabels" -}}
app.kubernetes.io/name: {{ include "sample-a.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{- define "sample-a.env" -}}
{{- range $key, $value := .Values.env }}
  - name: {{ $key }}
    value: {{ $value | quote }}
{{- end }}
  - name: PORT
    value: {{ .Values.service.internalPort | quote }}
  - name: URL_SCHEME
    value: http{{ if .Values.ingress.external.tls.enabled }}s{{ end }}
{{- end -}}


{{/*
ingot.sample-a.tls functions makes host-tls from host name
usage: {{ "www.example.com" | sample-a.utils.tls }}
output: www-example-com-tls
*/}}
{{- define "sample-a.utils.tls" -}}
{{- $host := index . | replace "." "-" -}}
{{- printf "%s-tls" $host -}}
{{- end -}}

{{- define "sample-a.secret_init_annotations" -}}
    {{- if .Values.secret_init_annotations }}
        {{- with .Values.secret_init_annotations }}
            {{- toYaml . | nindent 8 }}
        {{- end }}
    {{- end }}
{{- end -}}


{{/*
Create the name of the service account to use
*/}}
{{- define "sample-a.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "sample-a.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}
