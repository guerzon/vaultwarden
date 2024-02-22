{{- define "vaultwarden.pvcSpec" }}
{{- if (or .Values.data .Values.attachments) -}}
volumeClaimTemplates:
  {{- with .Values.data }}
  - metadata:
      name: {{ .name }}
      labels:
        app.kubernetes.io/component: vaultwarden
        app.kubernetes.io/name: {{ include "vaultwarden.fullname" $ }}
        app.kubernetes.io/instance: {{ include "vaultwarden.fullname" $ }}
      annotations:
        meta.helm.sh/release-name: {{ $.Release.Name | quote }}
        meta.helm.sh/release-namespace: {{ $.Release.Namespace | quote }}
        {{- if .keepPvc }}
        helm.sh/resource-policy: keep
        {{- end }}
    spec:
      accessModes:
        - "ReadWriteOnce"
      resources:
        requests:
          storage: {{ .size }}
      {{- with .class }}
      storageClassName: {{ . | quote }}
      {{- end }}
  {{- end }}
  {{- with .Values.attachments }}
  - metadata:
      name: {{ .name }}
      labels:
        app.kubernetes.io/component: vaultwarden
        app.kubernetes.io/name: {{ include "vaultwarden.fullname" $ }}
        app.kubernetes.io/instance: {{ include "vaultwarden.fullname" $ }}
      annotations:
        meta.helm.sh/release-name: {{ $.Release.Name | quote }}
        meta.helm.sh/release-namespace: {{ $.Release.Namespace | quote }}
        {{- if .keepPvc }}
        helm.sh/resource-policy: keep
        {{- end }}
    spec:
      accessModes:
        - "ReadWriteOnce"
      resources:
        requests:
          storage: {{ .size }}
      {{- with .class }}
      storageClassName: {{ . | quote }}
      {{- end }}
  {{- end }}
{{- end }}
{{- end }}