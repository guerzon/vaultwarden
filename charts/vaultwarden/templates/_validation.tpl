{{- /*
Validation checks that cause Helm to fail with a clear message
*/ -}}

{{- define "vaultwarden.validations" -}}
  {{- if and .Values.storage.local.enabled (eq .Values.database.type "default") -}}
    {{- fail "Invalid configuration: storage.local.enabled=true cannot be used with SQLite (database.type=default). Use an external database (mysql or postgresql)." -}}
  {{- end -}}
{{- end -}}