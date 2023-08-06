
## Parameters

### chart settings

| Name                | Description                          | Value                |
| ------------------- | ------------------------------------ | -------------------- |
| `image.registry`    | Vaultwarden image registry           | `docker.io`          |
| `image.repository`  | Vaultwarden image repository         | `vaultwarden/server` |
| `image.tag`         | Vaultwarden image tag                | `""`                 |
| `image.pullPolicy`  | Vaultwarden image pull policy        | `IfNotPresent`       |
| `image.pullSecrets` | Specify docker-registry secret names | `[]`                 |

### vaultwarden configuration: all vaultwarden.$SECTION.config values end up in $DATADIR/config.json


### See https://github.com/dani-garcia/vaultwarden/blob/main/.env.template for a complete overview


### vaultwarden.general settings

| Name                                    | Description                                   | Value     |
| --------------------------------------- | --------------------------------------------- | --------- |
| `vaultwarden.general.webVaultEnabled`   | Enable Web Vault                              | `true`    |
| `vaultwarden.general.rocket.port`       | Rocket port                                   | `8080`    |
| `vaultwarden.general.rocket.workers`    | Rocket number of workers                      | `10`      |
| `vaultwarden.general.websocket.enabled` | Enable websocket notifications                | `true`    |
| `vaultwarden.general.websocket.address` | Websocket listen address                      | `0.0.0.0` |
| `vaultwarden.general.websocket.port`    | Websocket listen port                         | `3012`    |
| `vaultwarden.general.config.domain`     | Domain name where the application is accessed | `nil`     |

### vaultwarden.Security settings

| Name                                                  | Description                                                                                                                    | Value         |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------ | ------------- |
| `vaultwarden.security.adminToken.value`               | Plain string containing the admin token.                                                                                       | `""`          |
| `vaultwarden.security.adminToken.existingSecret.name` | Specify an existing Kubernetes secret containing the admin token. Also set vaultwarden.security.adminToken.existingSecret.key. | `""`          |
| `vaultwarden.security.adminToken.existingSecret.key`  | When using vaultwarden.security.adminToken.existingSecret, specify the key containing the token.                               | `""`          |
| `vaultwarden.security.config.signupsAllowed`          | By default, anyone who can access your instance can register for a new account.                                                | `true`        |
| `vaultwarden.security.config.invitationsAllowed`      | Even when registration is disabled, organization administrators or owners can                                                  | `true`        |
| `vaultwarden.security.config.signupDomains`           | List of domain names for users allowed to register                                                                             | `contoso.com` |
| `vaultwarden.security.config.signupsVerify`           | Whether to require account verification for newly-registered users.                                                            | `true`        |
| `vaultwarden.security.config.showPassHint`            | Whether a password hint should be shown in the page.                                                                           | `false`       |

### vaultwarden.smtp settings

| Name                                                 | Description                                                 | Value      |
| ---------------------------------------------------- | ----------------------------------------------------------- | ---------- |
| `vaultwarden.smtp.username`                          | plaintext smtp username, conflicts with smtp.existingSecret | `""`       |
| `vaultwarden.smtp.password`                          | plaintext smtp password, conflicts with smtp.existingSecret | `""`       |
| `vaultwarden.smtp.existingSecret.name`               |                                                             | `""`       |
| `vaultwarden.smtp.existingSecret.username.secretKey` |                                                             | `""`       |
| `vaultwarden.smtp.existingSecret.password.secretKey` |                                                             | `""`       |
| `vaultwarden.smtp.config.host`                       | SMTP host                                                   | `""`       |
| `vaultwarden.smtp.config.security`                   | SMTP Encryption method                                      | `starttls` |
| `vaultwarden.smtp.config.port`                       | SMTP port                                                   | `25`       |
| `vaultwarden.smtp.config.from`                       | SMTP sender email address                                   | `""`       |
| `vaultwarden.smtp.config.fromName`                   | SMTP sender FROM                                            | `""`       |
| `vaultwarden.smtp.config.authMechanism`              | SMTP authentication mechanism                               | `Plain`    |
| `vaultwarden.smtp.config.acceptInvalidHostnames`     | Accept Invalid Hostnames                                    | `false`    |
| `vaultwarden.smtp.config.acceptInvalidCerts`         | Accept Invalid Certificates                                 | `false`    |
| `vaultwarden.smtp.config.debug`                      | SMTP debugging                                              | `false`    |

### vaultwarden.database settings

| Name                                     | Description                                                                                                                              | Value     |
| ---------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `vaultwarden.database.type`              | Database type, either mysql or postgresql                                                                                                | `default` |
| `vaultwarden.database.host`              | Database hostname or IP address                                                                                                          | `""`      |
| `vaultwarden.database.port`              | Database port                                                                                                                            | `""`      |
| `vaultwarden.database.username`          | Database username                                                                                                                        | `""`      |
| `vaultwarden.database.password`          | Database password                                                                                                                        | `""`      |
| `vaultwarden.database.dbName`            | Database name                                                                                                                            | `""`      |
| `vaultwarden.database.uriOverride`       | Manually specify the DB connection string                                                                                                | `""`      |
| `vaultwarden.database.existingSecret`    | Name of an existing secret containing the database URI                                                                                   | `""`      |
| `vaultwarden.database.existingSecretKey` | Key in the existing secret                                                                                                               | `""`      |
| `vaultwarden.database.connectionRetries` | Number of times to retry the database connection during startup, with 1 second delay between each retry, set to 0 to retry indefinitely. | `15`      |
| `vaultwarden.database.maxConnections`    | Define the size of the connection pool used for connecting to the database.                                                              | `10`      |

### vaultwarden.storage settings

| Name                          | Description                                 | Value   |
| ----------------------------- | ------------------------------------------- | ------- |
| `vaultwarden.storage.enabled` | Enable configuration for persistent storage | `true`  |
| `vaultwarden.storage.size`    | Storage size for /data                      | `15Gi`  |
| `vaultwarden.storage.class`   | Specify the storage class                   | `""`    |
| `vaultwarden.storage.dataDir` | Specify the data directory                  | `/data` |

### vaultwarden.logging settings

| Name                         | Description                              | Value |
| ---------------------------- | ---------------------------------------- | ----- |
| `vaultwarden.logging.config` | configuration for file logging           | `{}`  |
| `fullnameOverride`           | String to override the application name. | `""`  |

### Pod configuration

| Name                              | Description                                                                    | Value                |
| --------------------------------- | ------------------------------------------------------------------------------ | -------------------- |
| `podAnnotations`                  | Add extra annotations to the pod                                               | `{}`                 |
| `podLabels`                       | Add extra labels to the pod                                                    | `{}`                 |
| `ingress.enabled`                 | Deploy an ingress resource.                                                    | `false`              |
| `ingress.class`                   | Ingress resource class                                                         | `nginx`              |
| `ingress.nginxIngressAnnotations` | Add nginx specific ingress annotations                                         | `true`               |
| `ingress.additionalAnnotations`   | Additional annotations for the ingress resource.                               | `{}`                 |
| `ingress.labels`                  | Additional labels for the ingress resource.                                    | `{}`                 |
| `ingress.tls`                     | Enable TLS on the ingress resource.                                            | `true`               |
| `ingress.hostname`                | Hostname for the ingress.                                                      | `warden.contoso.com` |
| `ingress.path`                    | Default application path for the ingress                                       | `/`                  |
| `ingress.pathWs`                  | Path for the websocket ingress                                                 | `/notifications/hub` |
| `ingress.pathType`                | Path type for the ingress                                                      | `Prefix`             |
| `ingress.pathTypeWs`              | Path type for the ingress                                                      | `Exact`              |
| `ingress.tlsSecret`               | Kubernetes secret containing the SSL certificate when using the "nginx" class. | `""`                 |
| `ingress.nginxAllowList`          | Comma-separated list of IP addresses and subnets to allow.                     | `""`                 |
| `service.type`                    | Service type                                                                   | `ClusterIP`          |
| `service.annotations`             | Additional annotations for the vaultwarden service                             | `{}`                 |
| `service.labels`                  | Additional labels for the service                                              | `{}`                 |

### Extra containers Configuration

| Name             | Description                                                     | Value |
| ---------------- | --------------------------------------------------------------- | ----- |
| `initContainers` | extra init containers for initializing the vaultwarden instance | `[]`  |
| `sidecars`       | extra containers running alongside the vaultwarden instance     | `[]`  |

### Extra Configuration

| Name                | Description                           | Value |
| ------------------- | ------------------------------------- | ----- |
| `nodeSelector`      | Node labels for pod assignment        | `{}`  |
| `affinity`          | Affinity for pod assignment           | `{}`  |
| `tolerations`       | Tolerations for pod assignment        | `[]`  |
| `statefulsetlabels` | Additional labels for the statefulset | `{}`  |
