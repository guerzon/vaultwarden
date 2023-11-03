
## Parameters

### Vaultwarden settings

| Name                | Description                                   | Value                |
| ------------------- | --------------------------------------------- | -------------------- |
| `image.registry`    | Vaultwarden image registry                    | `docker.io`          |
| `image.repository`  | Vaultwarden image repository                  | `vaultwarden/server` |
| `image.tag`         | Vaultwarden image tag                         | `1.29.2`             |
| `image.pullPolicy`  | Vaultwarden image pull policy                 | `IfNotPresent`       |
| `image.pullSecrets` | Specify docker-registry secret names          | `[]`                 |
| `domain`            | Domain name where the application is accessed | `""`                 |
| `websocket.enabled` | Enable websocket notifications                | `true`               |
| `websocket.address` | Websocket listen address                      | `0.0.0.0`            |
| `websocket.port`    | Websocket listen port                         | `3012`               |
| `rocket.port`       | Rocket port                                   | `8080`               |
| `rocket.workers`    | Rocket number of workers                      | `10`                 |
| `webVaultEnabled`   | Enable Web Vault                              | `true`               |

### Pod configuration

| Name             | Description                      | Value |
| ---------------- | -------------------------------- | ----- |
| `podAnnotations` | Add extra annotations to the pod | `{}`  |
| `podLabels`      | Add extra labels to the pod      | `{}`  |

### Security settings

| Name                           | Description                                                                                              | Value               |
| ------------------------------ | -------------------------------------------------------------------------------------------------------- | ------------------- |
| `adminToken.existingSecret`    | Specify an existing Kubernetes secret containing the admin token. Also set adminToken.existingSecretKey. | `""`                |
| `adminToken.existingSecretKey` | When using adminToken.existingSecret, specify the key containing the token.                              | `""`                |
| `adminToken.value`             | Plain string containing the admin token.                                                                 | `R@ndomToken$tring` |
| `signupsAllowed`               | By default, anyone who can access your instance can register for a new account.                          | `true`              |
| `invitationsAllowed`           | Even when registration is disabled, organization administrators or owners can                            | `true`              |
| `signupDomains`                | List of domain names for users allowed to register                                                       | `""`                |
| `signupsVerify`                | Whether to require account verification for newly-registered users.                                      | `true`              |
| `showPassHint`                 | Whether a password hint should be shown in the page.                                                     | `false`             |
| `fullnameOverride`             | String to override the application name.                                                                 | `""`                |
| `invitationOrgName`            | String Name shown in the invitation emails that don't come from a specific organization                  | `Vaultwarden`       |
| `iconBlacklistNonGlobalIps`    | Whether block non-global IPs.                                                                            | `true`              |
| `ipHeader`                     | Client IP Header, used to identify the IP of the client                                                  | `X-Real-IP`         |
| `serviceAccount.create`        | Create a service account                                                                                 | `true`              |
| `serviceAccount.name`          | Name of the service account to create                                                                    | `vaultwarden-svc`   |

### Exposure Parameters

| Name                              | Description                                                                    | Value                |
| --------------------------------- | ------------------------------------------------------------------------------ | -------------------- |
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

### Database Configuration

| Name                         | Description                                                                                                                              | Value     |
| ---------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | --------- |
| `database.type`              | Database type, either mysql or postgresql                                                                                                | `default` |
| `database.host`              | Database hostname or IP address                                                                                                          | `""`      |
| `database.port`              | Database port                                                                                                                            | `""`      |
| `database.username`          | Database username                                                                                                                        | `""`      |
| `database.password`          | Database password                                                                                                                        | `""`      |
| `database.dbName`            | Database name                                                                                                                            | `""`      |
| `database.uriOverride`       | Manually specify the DB connection string                                                                                                | `""`      |
| `database.existingSecret`    | Name of an existing secret containing the database URI                                                                                   | `""`      |
| `database.existingSecretKey` | Key in the existing secret                                                                                                               | `""`      |
| `database.connectionRetries` | Number of times to retry the database connection during startup, with 1 second delay between each retry, set to 0 to retry indefinitely. | `15`      |
| `database.maxConnections`    | Define the size of the connection pool used for connecting to the database.                                                              | `10`      |

### SMTP Configuration

| Name                              | Description                                                                                                                                         | Value      |
| --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------- | ---------- |
| `smtp.existingSecret`             | Name of an existing secret containing the SMTP username and password. Also set smtp.username.existingSecretKey and smtp.password.existingSecretKey. | `""`       |
| `smtp.host`                       | SMTP host                                                                                                                                           | `""`       |
| `smtp.security`                   | SMTP Encryption method                                                                                                                              | `starttls` |
| `smtp.port`                       | SMTP port                                                                                                                                           | `25`       |
| `smtp.from`                       | SMTP sender email address                                                                                                                           | `""`       |
| `smtp.fromName`                   | SMTP sender FROM                                                                                                                                    | `""`       |
| `smtp.username.value`             | Username string for the SMTP authentication.                                                                                                        | `""`       |
| `smtp.username.existingSecretKey` | When using an existing secret, specify the key which contains the username.                                                                         | `""`       |
| `smtp.password.value`             | Password string for the SMTP authentication.                                                                                                        | `""`       |
| `smtp.password.existingSecretKey` | When using an existing secret, specify the key which contains the password.                                                                         | `""`       |
| `smtp.authMechanism`              | SMTP authentication mechanism                                                                                                                       | `Plain`    |
| `smtp.acceptInvalidHostnames`     | Accept Invalid Hostnames                                                                                                                            | `false`    |
| `smtp.acceptInvalidCerts`         | Accept Invalid Certificates                                                                                                                         | `false`    |
| `smtp.debug`                      | SMTP debugging                                                                                                                                      | `false`    |

### Storage Configuration

| Name              | Description                                 | Value   |
| ----------------- | ------------------------------------------- | ------- |
| `storage.enabled` | Enable configuration for persistent storage | `false` |
| `storage.size`    | Storage size for /data                      | `15Gi`  |
| `storage.class`   | Specify the storage class                   | `""`    |
| `storage.dataDir` | Specify the data directory                  | `/data` |

### Logging Configuration

| Name               | Description                         | Value                   |
| ------------------ | ----------------------------------- | ----------------------- |
| `logging.enabled`  | Enable logging to a file            | `false`                 |
| `logging.logfile`  | Specify logfile path for output log | `/data/vaultwarden.log` |
| `logging.loglevel` | Specify the log level               | `warn`                  |

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
