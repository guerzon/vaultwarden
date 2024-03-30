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
{{- with .Values.initContainers }}
initContainers:
{{- toYaml . | nindent 2 }}
{{- end }}
containers:
  - image: {{ .Values.image.registry }}/{{ .Values.image.repository }}:{{ .Values.image.tag }}
    imagePullPolicy: {{ .Values.image.pullPolicy }}
    name: vaultwarden
    envFrom:
      - configMapRef:
          name: {{ include "vaultwarden.fullname" . }}
    env:
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
      - containerPort: {{ .Values.websocket.port }}
        name: websocket
        protocol: TCP
    {{- if or (.Values.data) (.Values.attachments) }}
    volumeMounts:
      {{- with .Values.data }}
      - name: {{ .name }}
        mountPath: {{ default "/data" .path }}
      {{- end }}
      {{- with .Values.attachments }}
      - name: {{ .name }}
        mountPath: {{ default "/data/attachments" .path }}
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
        path: /alive
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
        path: /alive
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
        path: /alive
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
{{- if .Values.serviceAccount.create }}
serviceAccountName: {{ .Values.serviceAccount.name }}
{{- end }}
{{- end }}
