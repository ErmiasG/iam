{{/*
Expand the name of the chart.
*/}}
{{- define "kerberos.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kerberos.fullname" -}}
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
{{- define "kerberos.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kerberos.labels" -}}
helm.sh/chart: {{ include "kerberos.chart" . }}
{{ include "kerberos.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kerberos.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kerberos.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kerberos-ldap.labels" -}}
helm.sh/chart: {{ include "kerberos.chart" . }}
{{ include "kerberos-ldap.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kerberos-ldap.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kerberos.name" . }}-ladp
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kerberos.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "kerberos.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "kerberos.volumes"  -}}
- name: kdc-conf
  configMap:
    name: {{ template "kerberos.fullname" . }}-kdc-config
- name: krb5-conf
  configMap:
    name: {{ template "kerberos.fullname" . }}-krb5-config
- name: users-conf
  configMap:
    name: {{ template "kerberos.fullname" . }}-users-config
- name: {{ .Values.kdc.persistence.name }}
{{- if .Values.kdc.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ .Values.kdc.persistence.name }}
{{- else if not .Values.kdc.persistence.enabled }}
  emptyDir: {}
{{- end }}
- name: {{ .Values.ldap.persistence.name }}
{{- if .Values.ldap.persistence.enabled }}
  persistentVolumeClaim:
    claimName: {{ .Values.ldap.persistence.name }}
{{- else }}
  emptyDir: {}
{{- end -}}
{{- end }}

{{- define "kerberos.volumeMountsLdap"  -}}
- name: {{ .Values.ldap.persistence.name }} 
  mountPath: /var/lib/ldap
  subPath: data
- name: {{ .Values.ldap.persistence.name }} 
  mountPath: /etc/ldap/slapd.d
  subPath: config-data
{{- end }}

{{- define "kerberos.volumeMountsKrb"  -}}
- name: {{ .Values.kdc.persistence.name }}
  mountPath: /var/kerberos/krb5kdc
- name: kdc-conf
  mountPath: /var/kerberos/krb5kdc/kadm5.acl
  subPath: kadm5.acl
- mountPath: /var/kerberos/krb5kdc/kdc.conf
  name: kdc-conf
  subPath: kdc.conf
- mountPath: /etc/krb5/kdc.conf
  name: kdc-conf
  subPath: kdc.conf
- mountPath: /etc/krb5kdc/kdc.conf
  name: kdc-conf
  subPath: kdc.conf
- name: krb5-conf
  mountPath: /etc/krb5.conf 
  subPath: krb5.conf
{{- end }}

{{- define "kerberos.image_repository"  -}}
{{- if and .Values.global .Values.global.image.repository -}}
{{- .Values.global.image.repository -}}/{{ .Values.image.repository }}
{{- else -}}
{{ .Values.image.repository }}
{{- end }}
{{- end }}