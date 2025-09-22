{{- define "vaultwarden.podSpec" }}
{{- with .Values.dnsConfig }}
dnsConfig:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.nodeSelector }}
nodeSelector:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.affinity }}
affinity:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.tolerations }}
tolerations:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.priorityClassName }}
priorityClassName: {{ . | quote }}
{{- end }}
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.initContainers }}
initContainers:
{{- toYaml . | nindent 2 }}
{{- end }}
{{- if not .Values.enableServiceLinks }}
enableServiceLinks: false
{{- end }}
containers:
  - image: {{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    name: vaultwarden
    envFrom:
      - configMapRef:
          name: {{ include "vaultwarden.fullname" . }}
      {{- if .Values.image.extraVarsCM }}
      - configMapRef:
          name: {{ .Values.image.extraVarsCM }}
      {{- end }}
      {{- if .Values.image.extraVarsSecret }}
      - secretRef:
          name: {{ .Values.image.extraVarsSecret }}
      {{- end }}
    env:
      {{- range .Values.image.extraVars }}
      - name: {{ .key }}
        value: {{ .value | quote }}
      {{- end }}
      {{- if (.Values.image.extraSecrets) }}
      {{- range .Values.image.extraSecrets }}
      - name: {{ .key }}
        valueFrom:
          secretKeyRef:
            name: {{ include "vaultwarden.fullname" $ }}
            key: {{ .key }}
      {{- end }}
      {{- end }}
      {{- if or (.Values.yubico.secretKey.value) (.Values.yubico.secretKey.existingSecretKey) }}
      - name: YUBICO_SECRET_KEY
        valueFrom:
          secretKeyRef:
            name: {{ default (include "vaultwarden.fullname" .) .Values.yubico.existingSecret }}
            key: {{ default "YUBICO_SECRET_KEY" .Values.yubico.secretKey.existingSecretKey }}
      {{- end }}
      {{- if or (.Values.duo.sKey.value) (.Values.duo.sKey.existingSecretKey) }}
      - name: DUO_SKEY
        valueFrom:
          secretKeyRef:
            name: {{ default (include "vaultwarden.fullname" .) .Values.duo.existingSecret }}
            key: {{ default "DUO_SKEY" .Values.duo.sKey.existingSecretKey }}
      {{- end }}  
      {{- if or (.Values.smtp.username.value) (.Values.smtp.username.existingSecretKey )}}
      - name: SMTP_USERNAME
        valueFrom:
          secretKeyRef:
            name: {{ default (include "vaultwarden.fullname" .) .Values.smtp.existingSecret }}
            key: {{ default "SMTP_USERNAME" .Values.smtp.username.existingSecretKey }}
      {{- end }}
      {{- if or (.Values.smtp.password.value) (.Values.smtp.password.existingSecretKey )}}
      - name: SMTP_PASSWORD
        valueFrom:
          secretKeyRef:
            name: {{ default (include "vaultwarden.fullname" .) .Values.smtp.existingSecret }}
            key: {{ default "SMTP_PASSWORD" .Values.smtp.password.existingSecretKey }}
      {{- end }}
      {{- if .Values.adminToken }}
      - name: ADMIN_TOKEN
        valueFrom:
          secretKeyRef:
            name: {{ default (include "vaultwarden.fullname" .) .Values.adminToken.existingSecret }}
            key: {{ default "ADMIN_TOKEN" .Values.adminToken.existingSecretKey }}
      {{- else }}
      - name: DISABLE_ADMIN_TOKEN
        value: "true"
      {{- end }}
      {{- if or (.Values.pushNotifications.installationId.value) (.Values.pushNotifications.installationId.existingSecretKey )}}
      - name: PUSH_INSTALLATION_ID
        valueFrom:
          secretKeyRef:
            name: {{ default (include "vaultwarden.fullname" .) .Values.pushNotifications.existingSecret }}
            key: {{ default "PUSH_INSTALLATION_ID" .Values.pushNotifications.installationId.existingSecretKey }}
      {{- end }}
      {{- if or (.Values.pushNotifications.installationKey.value) (.Values.pushNotifications.installationKey.existingSecretKey )}}
      - name: PUSH_INSTALLATION_KEY
        valueFrom:
          secretKeyRef:
            name: {{ default (include "vaultwarden.fullname" .) .Values.pushNotifications.existingSecret }}
            key: {{ default "PUSH_INSTALLATION_KEY" .Values.pushNotifications.installationKey.existingSecretKey }}
      {{- end }}
      {{- if and ( eq .Values.database.type "postgresql") .Values.database.existingSecret (not .Values.database.existingSecretKey)}}
      - name: DATABASE_URL
        value: "postgresql://{{ .Values.database.host }}"
      - name: PGPORT
        value: {{ .Values.database.port | quote }}
      - name: PGDATABASE
        value: {{ .Values.database.dbName | quote }}
      - name: PGUSER
        {{- if .Values.database.existingSecretUserKey}}
        valueFrom:
          secretKeyRef:
            name: {{ .Values.database.existingSecret | quote }}
            key: {{ .Values.database.existingSecretUserKey | quote }}
        {{- else }}
        value: {{ .Values.database.username | quote }}
        {{- end }}
      - name: PGPASSWORD
        {{- if .Values.database.existingSecretPasswordKey}}
        valueFrom:
          secretKeyRef:
            name: {{ .Values.database.existingSecret | quote }}
            key: {{ .Values.database.existingSecretPasswordKey | quote }}
        {{- else }}
        value: {{ .Values.database.password }}
        {{- end }}
      {{- else if ne "default" .Values.database.type }}
      - name: DATABASE_URL
        {{- if .Values.database.existingSecret }}
        valueFrom:
          secretKeyRef:
            name: {{ .Values.database.existingSecret }}
            key: {{ .Values.database.existingSecretKey }}
        {{- else }}
        {{- if .Values.database.uriOverride }}
        value: {{ .Values.database.uriOverride }}
        {{- else }}
        value: {{ include "dbString" . | quote }}
        {{- end }}
        {{- end }}
      {{- end }}
    ports:
      - containerPort: 8080
        name: http
        protocol: TCP
    {{- if or (.Values.storage.existingVolumeClaim) (.Values.extraVolumeMounts) }}
    volumeMounts:
    {{- with .Values.extraVolumeMounts }}
    {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- with .Values.storage.existingVolumeClaim }}
      - name: vaultwarden-data
        mountPath: {{ default "/data" .dataPath }}
      - name: vaultwarden-data
        mountPath: {{ default "/data/attachments" .attachmentsPath }}
    {{- end }}
    {{- else }}
    {{- if or (.Values.storage.data) (.Values.storage.attachments) }}
    volumeMounts:
      {{- with .Values.storage.data }}
      - name: {{ .name }}
        mountPath: {{ default "/data" .path }}
      {{- end }}
      {{- with .Values.storage.attachments }}
      - name: {{ .name }}
        mountPath: {{ default "/data/attachments" .path }}
      {{- end }}
    {{- end }}
    {{- end }}
    resources:
    {{- toYaml .Values.resources | nindent 6 }}
    {{- with .Values.securityContext }}
    securityContext:
    {{- toYaml . | nindent 6 }}
    {{- end }}
    {{- if .Values.livenessProbe.enabled }}
    livenessProbe:
      httpGet:
        path: {{ .Values.livenessProbe.path }}
        port: http
      initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
      periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
      timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
      successThreshold: {{ .Values.livenessProbe.successThreshold }}
      failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
    {{- end }}
    {{- if .Values.readinessProbe.enabled }}
    readinessProbe:
      httpGet:
        path: {{ .Values.readinessProbe.path }}
        port: http
      initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
      periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
      timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
      successThreshold: {{ .Values.readinessProbe.successThreshold }}
      failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
    {{- end }}
    {{- if .Values.startupProbe.enabled }}
    startupProbe:
      httpGet:
        path: {{ .Values.startupProbe.path }}
        port: http
      initialDelaySeconds: {{ .Values.startupProbe.initialDelaySeconds }}
      periodSeconds: {{ .Values.startupProbe.periodSeconds }}
      timeoutSeconds: {{ .Values.startupProbe.timeoutSeconds }}
      successThreshold: {{ .Values.startupProbe.successThreshold }}
      failureThreshold: {{ .Values.startupProbe.failureThreshold }}
    {{- end }}
    {{- with .Values.sidecars }}
    {{- toYaml . | nindent 2 }}
    {{- end }}
{{- if or (.Values.storage.existingVolumeClaim) (.Values.extraVolumes) }}
volumes:
{{- with .Values.extraVolumes }}
{{- toYaml . | nindent 2 }}
{{- end }}
{{- with .Values.storage.existingVolumeClaim }}
  - name: vaultwarden-data
    persistentVolumeClaim:
      claimName: {{ .claimName }}
{{- end }}
{{- end }}
{{- if .Values.serviceAccount.create }}
serviceAccountName: {{ .Values.serviceAccount.name }}
{{- end }}
{{- with .Values.image.pullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
