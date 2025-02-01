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
{{- with .Values.podSecurityContext }}
securityContext:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- if or .Values.initContainers (eq (include "vaultwarden.doBackup" .) "true") }}
initContainers:
{{- with .Values.initContainers }}
{{- toYaml . | nindent 2 }}
{{- end }}

{{- if eq (include "vaultwarden.doBackup" .) "true" }}
  # Copy rclone config from read-only secret mount to writable share
  # https://github.com/rclone/rclone/issues/3655
  - name: copy-config
    image: busybox:latest
    command: ["sh", "-c", "cp -v /src-config/rclone.conf /config/"]
    volumeMounts:
      - name: backup-secret-conf
        mountPath: "/src-config/"
        readOnly: true
      - name: config
        mountPath: "/config/"
{{- end }}
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
      {{- if ne "default" .Values.database.type }}
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
    {{- if .Values.storage.existingVolumeClaim }}
    {{- with .Values.storage.existingVolumeClaim }}
    volumeMounts:
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
  {{- if eq (include "vaultwarden.doBackup" .) "true" }}
  {{- range .Values.backup.backups }}
  - image: {{ $.Values.backup.image }}
    name: backup-{{ .name }}
    securityContext:
      allowPrivilegeEscalation: false
    env:
      - name: DATA_DIR
        value: {{ default "/data" .path | quote }}
      - name: RCLONE_REMOTE_NAME
        value: {{ $.Values.backup.remoteName | quote }}
      - name: RCLONE_REMOTE_DIR
        value: {{ .remoteDir | quote }}
      - name: RCLONE_GLOBAL_FLAG
        value: "{{ $.Values.backup.globalFlags }} --config /config/rclone.conf"
      - name: CRON
        value: {{ .cron | quote }}
      - name: ZIP_PASSWORD
        value: {{ $.Values.backup.zipPassword | quote }}
      - name: BACKUP_KEEP_DAYS
        value: {{ .keepDays | quote }}
      - name: BACKUP_FILE_DATE_SUFFIX
        value: {{ .fileDateSuffix | quote }}
      - name: TIMEZONE
        value: {{ $.Values.backup.timezone | quote }}
      {{- if .healthCheckPing }}
      - name: PING_URL
        value: {{ (tpl .healthCheckPing  $) | quote }}
      {{- end }}
      {{- if $.Values.backup.smtp.enabled }}
      - name: MAIL_SMTP_ENABLE
        value: "true"
      - name: MAIL_SMTP_VARIABLES
        value: {{ $.Values.backup.smtp.smtpVariables | quote }}
      - name: MAIL_TO
        value: {{ $.Values.backup.smtp.mailTo | quote }}
      - name: MAIL_WHEN_SUCCESS
        value: {{ $.Values.backup.smtp.mailWhenSuccess | quote }}
      - name: MAIL_WHEN_FAILURE
        value: {{ $.Values.backup.smtp.mailWhenFailure | quote }}
      {{- end }}
      # When run as non-root, script cannot create crontabs in home folcer
    volumeMounts:
      - name: vaultwarden-data
        mountPath: {{ default "/data" $.Values.storage.data.path }}
      - name: config
        mountPath: "/config/"
  {{- end }}
  {{- end }}
    {{- with .Values.sidecars }}
    {{- toYaml . | nindent 2 }}
    {{- end }}
{{- if or .Values.storage.existingVolumeClaim (eq (include "vaultwarden.doBackup" .) "true" ) }}
volumes:
  {{- if .Values.storage.existingVolumeClaim }}
  {{- with .Values.storage.existingVolumeClaim }}
  - name: vaultwarden-data
    persistentVolumeClaim:
      claimName: {{ .claimName }}
  {{- end }}
  {{- end }}
  {{- if eq (include "vaultwarden.doBackup" .) "true" }}
  - name: backup-secret-conf
    secret:
      secretName: {{ include "vaultwarden.fullname" . }}-rclone
      optional: false
      # readable by user/owner
      defaultMode: 0400
  - name: config
    emptyDir: {}
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
