
# Vaultwarden

[Vaultwarden](https://github.com/dani-garcia/vaultwarden), is an alternative implementation of the Bitwarden server API written in Rust and compatible with [upstream Bitwarden clients](https://bitwarden.com/download/).

## Usage

Basic usage:

```bash
export NAMESPACE=vaultwarden
export DOMAIN_NAME=pass.company.com

helm install vaultwarden-release vaultwarden/vaultwarden \
  --namespace $NAMESPACE \
  --set "ingress.enabled=true" \
  --set "ingress.hostname=$DOMAIN_NAME"
```

To deploy the chart to another namespace using custom values in the file `demo.yaml`:

```bash
export NAMESPACE=vaultwarden-demo
export RELEASE_NAME=vaultwarden-demo
helm upgrade -i \
  -n $NAMESPACE $RELEASE_NAME vaultwarden/vaultwarden \
  -f demo.yaml
```

## General configuration

This chart deploys `vaultwarden` from pre-built images on [Docker Hub](https://hub.docker.com/r/vaultwarden/server/tags): `vaultwarden/server`. The image can be defined by specifying the tag with `image.tag`.

Example that uses the Alpine-based image `1.24.0-alpine` and an existing secret that contains registry credentials:

```yaml
image:
  registry: ghcr.io
  repository: guerzon/vaultwarden
  tag: "1.24.0-alpine"
  pullSecrets:
    - name: myRegKey
```

**Important**: specify the URL used by users with the `domain` variable, otherwise, some functionalities might not work:

```yaml
domain: "https://vaultwarden.contoso.com:9443/"
```

Detailed configuration options can be found in the [General settings](#general-settings) section.

## Database options

By default, `vaultwarden` uses a SQLite database located in `/data/db.sqlite3`. However, it is also possible to make use of an external database, in particular either [MySQL](https://www.mysql.com/downloads/) or [PostgreSQL](https://www.postgresql.org).

To configure an external database, set `database.type` to either `mysql` or `postgresql` and specify the datase connection information.

Example for using an external MySQL database:

```yaml
database:
  type: mysql
  host: database.contoso.eu
  username: appuser
  password: apppassword
  dbName: prodapp
```

You can also specify the connection string:

```yaml
database:
  type: postgresql
  uriOverride: "postgresql://appuser:apppassword@pg.contoso.eu:5433/qualdb"
```

Alternatively, you could create a Kubernetes secret containing the database URI:

```bash
DB_STRING="postgresql://appuser:apppassword@pg.contoso.eu:5433/qualdb"
kubectl -n vaultwarden create secret generic prod-db-creds --from-literal=secret-uri=$DB_STRING
```

Then pass the name of the secret and the key to the chart:

```yaml
database:
  type: postgresql
  existingSecret: "prod-db-creds"
  existingSecretKey: "secret-uri"
```

Detailed configuration options can be found in the [Database Configuration](#database-settings) section.

## SSL and Ingress

This chart supports the usage of existing Ingress Controllers for exposing the `vaultwarden` deployment.

### nginx-ingress

Nginx ingress controller can be installed by following [this](https://kubernetes.github.io/ingress-nginx/deploy/) guide. An SSL certificate can be added as a secret with a few commands:

```bash
cd <dir-containing-the-certs>
kubectl create secret -n vaultwarden \
  tls vw-constoso-com-crt \
  --key privkey.pem \
  --cert fullchain.pem
```

Once both prerequisites are ready, values can be set as follows:

```yaml
ingress:
  enabled: true
  class: "nginx"
  tlsSecret: vw-constoso-com-crt
  hostname: vaultwarden.contoso.com
  allowList: "10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16"
```

If you intend on making your ingress available via multiple hostnames, you can invoke the `ingress.additionalHostnames` as follows:

```yaml
ingress:
  enabled: true
  class: "nginx"
  tlsSecret: vw-contoso-com-crt
  hostname: vaultwarden.contoso.com
  additionalHostnames:
    - vw.contoso.com
  allowList: "10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16"
```

### AWS LB Controller

When using AWS, the [AWS Load Balancer controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/) can be used together with [ACM](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/cert_discovery/).

Example for AWS:

```yaml
ingress:
  enabled: true
  class: "alb"
  hostname: vaultwarden.contoso.com
  additionalAnnotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/tags: Environment=dev,Team=test
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:eu-central-1:ACCOUNT:certificate/LONGID"
```

Visit [this](https://medium.com/@sreafterhours/deploy-vaultwarden-to-amazon-eks-using-terraform-terragrunt-and-helm-69a0a7396625) article for a tutorial for deploying an EKS cluster and then installing this chart.

Detailed configuration options can be found in the [Exposure Settings](#exposure-settings) section.

## High Availability

Set the following to run multiple deployment/statefulset replicas:

```yaml
replicas: 10

service:
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800
```

## Security

### Admin page

An insecure string token can be generated with: `openssl rand -base64 48` and can be used for the admin token. However, from v1.28.0 and later, it is now possible to pass a hashed value to the admin token:

```bash
echo -n "R@ndomTokenString" | argon2 "$(openssl rand -base64 32)" -e -id -k 19456 -t 2 -p 1
```

Please see [this](https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page#secure-the-admin_token) guide for more information.

```yaml
adminToken:
  value: "khit9gYQV6ax9LKTTm+s6QbZi5oiuR+3s1PEn9q3IRmCl9IQn7LmBpmFCOYTb7Mr"
```

You can also [disable](https://github.com/dani-garcia/vaultwarden/wiki/Disable-admin-token) the admin token by passing `--set adminToken=null` to `helm`. Doing so will pass the disable the authentication to the admin page. Do this if you know what you are doing.

### Service account

By default, the chart deploys a [service account](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/) called `vaultwarden-svc`.

```yaml
serviceAccount:
  create: true
  name: "vaultwarden-svc"
```

### MFA/2FA settings

You can configure YubiKey authentication as described [here](https://github.com/dani-garcia/vaultwarden/wiki/Enabling-Yubikey-OTP-authentication). An example configuration is as follows:

```yaml
yubico:
  clientId: "ABCDE"
  secretKey:
    value: "12345"
```

You could also use an existing Kubernetes secret:

```yaml
yubico:
  clientId: "ABCDE"
  existingSecret: "yubisecrets"
  secretKey:
    existingSecretKey: "YUBI"
```

You can configure Duo authentication as described [here](https://help.bitwarden.com/article/setup-two-step-login-duo/#create-a-duo-security-account). An example configuration is as follows:

```yaml
duo:
  hostname: api.duohelp.com
  iKey: "999888"
  sKey:
    value: "HELLO"
```

You could also use an existing Kubernetes secret:

```yaml
duo:
  hostname: api.duohelp.com
  iKey: "999888"
  existingSecret: "duosecrets"
  sKey:
    existingSecretKey: "DUO"
```

## Mail settings

To enable the SMTP service, make sure that at a minimum, `smtp.host` and `smtp.from` are set.

```yaml
smtp:
  host: mx01.contoso.com
  from: no-reply@contoso.com
  fromName: "Vault Administrator"
  username:
    value: admin
  password:
    value: password
  acceptInvalidHostnames: "true"
  acceptInvalidCerts: "true"
```

You could also use an existing Kubernetes secret that contains the SMTP username and password:

```yaml
smtp:
  host: mx01.contoso.com
  from: no-reply@contoso.com
  fromName: "Vault Administrator"
  existingSecret: smtpsecrets
  username:
    existingSecretKey: SMTP_USERNAME
  password:
    existingSecretKey: SMTP_PASSWORD
```

Detailed configuration options can be found in the [SMTP Configuration](#smtp-configuration) section.

## Persistent storage

### Building Persistant Storage Through Helm

Vaultwarden requires persistent storage for its attachments and icons cache.

To use persistent storage using a claim, set the `storage.data` dictionary. Optionally set a different path using the `path` key. The following example sets the storage class to an already-installed Rancher's [local path storage](https://github.com/rancher/local-path-provisioner) provisioner.

```yaml
data:
  name: "vaultwarden-data"
  size: "15Gi"
  class: "local-path"
```

Example for AWS:

```yaml
data:
  name: "vaultwarden-data"
  size: "10Gi"
  class: "gp2"
  path: "/srv/vaultwarden-data"
```

To use persistent storage for attachments, set the `storage.attachments` dictionary. Optionally set a different path. Note that by default, the path is `/data/attachments`.

```yaml
attachments:
  name: "vaultwarden-data"
  size: "15Gi"
  class: "local-path"
```

In case you want to keep the existing persistent volume claim during uninstall and redeployments, set the option `keepPvc: true`
(This will be ignored for StatefulSets and is only relevant for `resourceType: Deployment`)

```yaml
attachments:
  name: "vaultwarden-data"
  size: "15Gi"
  class: "local-path"
  keepPvc: true
```

### Using an Existing Persistent Volume Claim

In case you want to use an existing PVC to store your data and attachments (i.e. NAS), `storage.existingVolumeClaim` can be set 
which will update the PodSpec's to use the provided PVC.  Note, that use of this value will ignore the values of both `storage.data` 
and `storage.attachments` values.

```yaml
existingVolumeClaim:
    claimName: "vaultwarden-pvc"
    dataPath: "/data"
    attachmentsPath: /data/attachments
```

## Uninstall

To uninstall/delete the `vaultwarden-demo` release:

```bash
export NAMESPACE=vaultwarden
export RELEASE_NAME=vaultwarden-demo

helm -n $NAMESPACE uninstall $RELEASE_NAME
```

## Parameters

### Kubernetes settings

| Name                    | Description                                                                               | Value                |
| ----------------------- | ----------------------------------------------------------------------------------------- | -------------------- |
| `image.registry`        | Vaultwarden image registry                                                                | `docker.io`          |
| `image.repository`      | Vaultwarden image repository                                                              | `vaultwarden/server` |
| `image.tag`             | Vaultwarden image tag                                                                     | `1.32.0-alpine`      |
| `image.pullPolicy`      | Vaultwarden image pull policy                                                             | `IfNotPresent`       |
| `image.pullSecrets`     | Specify docker-registry secrets                                                           | `[]`                 |
| `image.extraSecrets`    | Vaultwarden image extra secrets                                                           | `[]`                 |
| `image.extraVars`       | Vaultwarden image extra vars                                                              | `[]`                 |
| `fullnameOverride`      | String to override the application name.                                                  | `""`                 |
| `resourceType`          | Can be either Deployment or StatefulSet                                                   | `""`                 |
| `commonAnnotations`     | Annotations for the deployment or statefulset                                             | `{}`                 |
| `configMapAnnotations`  | Add extra annotations to the configmap                                                    | `{}`                 |
| `podAnnotations`        | Add extra annotations to the pod                                                          | `{}`                 |
| `commonLabels`          | Additional labels for the deployment or statefulset                                       | `{}`                 |
| `podLabels`             | Add extra labels to the pod                                                               | `{}`                 |
| `initContainers`        | extra init containers for initializing the vaultwarden instance                           | `[]`                 |
| `sidecars`              | extra containers running alongside the vaultwarden instance                               | `[]`                 |
| `nodeSelector`          | Node labels for pod assignment                                                            | `{}`                 |
| `affinity`              | Affinity for pod assignment                                                               | `{}`                 |
| `tolerations`           | Tolerations for pod assignment                                                            | `[]`                 |
| `serviceAccount.create` | Create a service account                                                                  | `true`               |
| `serviceAccount.name`   | Name of the service account to create                                                     | `vaultwarden-svc`    |
| `podSecurityContext`    | Pod security options                                                                      | `{}`                 |
| `securityContext`       | Default security options to run vault as read only container without privilege escalation | `{}`                 |
| `dnsConfig`             | Pod DNS options                                                                           | `{}`                 |
| `enableServiceLinks`    | Enable service links, Kubernetes default is true                                          | `true`               |

### Reliability configuration

| Name                                 | Description                                                               | Value    |
|--------------------------------------|---------------------------------------------------------------------------|----------|
| `livenessProbe.enabled`              | Enable liveness probe                                                     | `true`   |
| `livenessProbe.initialDelaySeconds`  | Delay before liveness probe is initiated                                  | `5`      |
| `livenessProbe.timeoutSeconds`       | How long to wait for the probe to succeed                                 | `1`      |
| `livenessProbe.periodSeconds`        | How often to perform the probe                                            | `10`     |
| `livenessProbe.successThreshold`     | Minimum consecutive successes for the probe to be considered successful   | `1`      |
| `livenessProbe.failureThreshold`     | Minimum consecutive failures for the probe to be considered failed        | `10`     |
| `livenessProbe.path`                 | Path which probe tries to resolve, override when non-root path deployment | `/alive` |
| `readinessProbe.enabled`             | Enable readiness probe                                                    | `true`   |
| `readinessProbe.initialDelaySeconds` | Delay before readiness probe is initiated                                 | `5`      |
| `readinessProbe.timeoutSeconds`      | How long to wait for the probe to succeed                                 | `1`      |
| `readinessProbe.periodSeconds`       | How often to perform the probe                                            | `10`     |
| `readinessProbe.successThreshold`    | Minimum consecutive successes for the probe to be considered successful   | `1`      |
| `readinessProbe.failureThreshold`    | Minimum consecutive failures for the probe to be considered failed        | `3`      |
| `readinessProbe.path`                | Path which probe tries to resolve, override when non-root path deployment | `/alive` |
| `startupProbe.enabled`               | Enable startup probe                                                      | `false`  |
| `startupProbe.initialDelaySeconds`   | Delay before startup probe is initiated                                   | `5`      |
| `startupProbe.timeoutSeconds`        | How long to wait for the probe to succeed                                 | `1`      |
| `startupProbe.periodSeconds`         | How often to perform the probe                                            | `10`     |
| `startupProbe.successThreshold`      | Minimum consecutive successes for the probe to be considered successful   | `1`      |
| `startupProbe.failureThreshold`      | Minimum consecutive failures for the probe to be considered failed        | `10`     |
| `startupProbe.path`                  | Path which probe tries to resolve, override when non-root path deployment | `/alive` |
| `resources`                          | Resource configurations                                                   | `{}`     |
| `strategy`                           | Resource configurations                                                   | `{}`     |
| `podDisruptionBudget.enabled`        | Enable PodDisruptionBudget settings                                       | `false`  |
| `podDisruptionBudget.minAvailable`   | Minimum number/percentage of pods that should remain scheduled.           | `1`      |
| `podDisruptionBudget.maxUnavailable` | Maximum number/percentage of pods that may be made unavailable            | `nil`    |

### Persistent data configuration

| Name              | Description                                                               | Value  |
| ----------------- | ------------------------------------------------------------------------- | ------ |
| `data`            | Data directory configuration, refer to values.yaml for parameters.        | `{}`   |
| `attachments`     | Attachments directory configuration, refer to values.yaml for parameters. | `{}`   |
| `webVaultEnabled` | Enable Web Vault                                                          | `true` |

### Database settings

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

### Push Notifications

| Name                                                  | Description                                                                         | Value                            |
| ----------------------------------------------------- | ----------------------------------------------------------------------------------- | -------------------------------- |
| `pushNotifications.enabled`                           | Enable the push notification service                                                | `false`                          |
| `pushNotifications.existingSecret`                    | Name of an existing secret containing the Bitwarden installation id and key         | `""`                             |
| `pushNotifications.installationId.value`              | Bitwarden installation id string                                                    | `""`                             |
| `pushNotifications.installationId.existingSecretKey`  | When using an existing secret, specify the key which contains the installation id.  | `""`                             |
| `pushNotifications.installationKey.value`             | Bitwarden installation key string                                                   | `""`                             |
| `pushNotifications.installationKey.existingSecretKey` | When using an existing secret, specify the key which contains the installation key. | `""`                             |
| `pushNotifications.relayUri`                          | Change Bitwarden relay uri.                                                         | `https://push.bitwarden.com`     |
| `pushNotifications.identityUri`                       | Change Bitwarden identity uri.                                                      | `https://identity.bitwarden.com` |

### Scheduled jobs

| Name                          | Description                                                                                          | Value          |
| ----------------------------- | ---------------------------------------------------------------------------------------------------- | -------------- |
| `emergencyNotifReminderSched` | Cron schedule of the job that sends expiration reminders to emergency access grantors.               | `0 3 * * * *`  |
| `emergencyRqstTimeoutSched`   | Cron schedule of the job that grants emergency access requests that have met the required wait time. | `0 7 * * * *`  |
| `eventCleanupSched`           | Cron schedule of the job that cleans old events from the event table.                                | `0 10 0 * * *` |
| `eventsDayRetain`             | Number of days to retain events stored in the database.                                              | `""`           |

### General settings

| Name                        | Description                                                                                  | Value         |
| --------------------------- | -------------------------------------------------------------------------------------------- | ------------- |
| `domain`                    | Domain name where the application is accessed                                                | `""`          |
| `sendsAllowed`              | Controls whether users are allowed to create Bitwarden Sends.                                | `true`        |
| `hibpApiKey`                | HaveIBeenPwned API Key                                                                       | `""`          |
| `orgAttachmentLimit`        | Max Kilobytes of attachment storage allowed per organization.                                | `""`          |
| `userAttachmentLimit`       | Max kilobytes of attachment storage allowed per user.                                        | `""`          |
| `userSendLimit`             | Max kilobytes of send storage allowed per user.                                              | `""`          |
| `trashAutoDeleteDays`       | Number of days to wait before auto-deleting a trashed item.                                  | `""`          |
| `signupsAllowed`            | By default, anyone who can access your instance can register for a new account.              | `true`        |
| `signupsVerify`             | Whether to require account verification for newly-registered users.                          | `true`        |
| `signupDomains`             | List of domain names for users allowed to register. For example:                             | `""`          |
| `orgEventsEnabled`          | Controls whether event logging is enabled for organizations                                  | `false`       |
| `orgCreationUsers`          | Controls which users can create new orgs.                                                    | `""`          |
| `invitationsAllowed`        | Even when registration is disabled, organization administrators or owners can                | `true`        |
| `invitationOrgName`         | String Name shown in the invitation emails that don't come from a specific organization      | `Vaultwarden` |
| `invitationExpirationHours` | The number of hours after which an organization invite token, emergency access invite token, | `120`         |
| `emergencyAccessAllowed`    | Controls whether users can enable emergency access to their accounts.                        | `true`        |
| `emailChangeAllowed`        | Controls whether users can change their email.                                               | `true`        |
| `showPassHint`              | Controls whether a password hint should be shown directly in the web page if                 | `false`       |

### Advanced settings

| Name                             | Description                                                                                                                                          | Value                                                                                                                                    |
| -------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `ipHeader`                       | Client IP Header, used to identify the IP of the client                                                                                              | `X-Real-IP`                                                                                                                              |
| `iconService`                    | The predefined icon services are: internal, bitwarden, duckduckgo, google.                                                                           | `internal`                                                                                                                               |
| `iconRedirectCode`               | Icon redirect code                                                                                                                                   | `302`                                                                                                                                    |
| `iconBlacklistNonGlobalIps`      | Whether block non-global IPs.                                                                                                                        | `true`                                                                                                                                   |
| `experimentalClientFeatureFlags` | Comma separated list of experimental features to enable in clients, make sure to check which features are already enabled by default (.env.template) | `nil`                                                                                                                                    |
| `requireDeviceEmail`             | Require new device emails. When a user logs in an email is required to be sent.                                                                      | `false`                                                                                                                                  |
| `extendedLogging`                | Enable extended logging, which shows timestamps and targets in the logs                                                                              | `true`                                                                                                                                   |
| `logTimestampFormat`             | Timestamp format used in extended logging.                                                                                                           | `%Y-%m-%d %H:%M:%S.%3f`                                                                                                                  |
| `logging.logLevel`               | Specify the log level                                                                                                                                | `""`                                                                                                                                     |
| `logging.logFile`                | Log to a file                                                                                                                                        | `""`                                                                                                                                     |
| `adminToken.existingSecret`      | Specify an existing Kubernetes secret containing the admin token. Also set adminToken.existingSecretKey.                                             | `""`                                                                                                                                     |
| `adminToken.existingSecretKey`   | When using adminToken.existingSecret, specify the key containing the token.                                                                          | `""`                                                                                                                                     |
| `adminToken.value`               | Plain or argon2 string containing the admin token.                                                                                                   | `$argon2id$v=19$m=19456,t=2,p=1$Vkx1VkE4RmhDMUhwNm9YVlhPQkVOZk1Yc1duSDdGRVYzd0Y5ZkgwaVg0Yz0$PK+h1ANCbzzmEKaiQfCjWw+hWFaMKvLhG2PjRanH5Kk` |
| `adminRateLimitSeconds`          | Number of seconds, on average, between admin login requests from the same IP address before rate limiting kicks in.                                  | `300`                                                                                                                                    |
| `adminRateLimitMaxBurst`         | Allow a burst of requests of up to this size, while maintaining the average indicated by adminRateLimitSeconds.                                      | `3`                                                                                                                                      |
| `timeZone`                       | Specify timezone different from the default (UTC).                                                                                                   | `""`                                                                                                                                     |

### BETA Features

| Name               | Description                                                 | Value   |
| ------------------ | ----------------------------------------------------------- | ------- |
| `orgGroupsEnabled` | Controls whether group support is enabled for organizations | `false` |

### MFA/2FA settings

| Name                                 | Description                                                                                               | Value |
| ------------------------------------ | --------------------------------------------------------------------------------------------------------- | ----- |
| `yubico.clientId`                    | Yubico client ID                                                                                          | `""`  |
| `yubico.existingSecret`              | Name of an existing secret containing the Yubico secret key. Also set yubico.secretKey.existingSecretKey. | `""`  |
| `yubico.secretKey.value`             | secretKey plain text                                                                                      | `""`  |
| `yubico.secretKey.existingSecretKey` | When using an existing secret, specify the key which contains the secretKey.                              | `""`  |
| `yubico.server`                      | Specify a Yubico server, otherwise the default servers will be used                                       | `""`  |
| `duo.iKey`                           | Duo Integration Key                                                                                       | `""`  |
| `duo.existingSecret`                 | Name of an existing secret containing the Duo skey. Also set duo.sKey.existingSecretKey.                  | `""`  |
| `duo.sKey.value`                     | sKey plain text                                                                                           | `""`  |
| `duo.sKey.existingSecretKey`         | When using an existing secret, specify the key which contains the sKey.                                   | `""`  |
| `duo.hostname`                       | Duo API hostname                                                                                          | `""`  |

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

### Exposure settings

| Name                              | Description                                                                    | Value                |
| --------------------------------- | ------------------------------------------------------------------------------ | -------------------- |
| `rocket.address`                  | Address to bind to                                                             | `0.0.0.0`            |
| `rocket.port`                     | Rocket port                                                                    | `8080`               |
| `rocket.workers`                  | Rocket number of workers                                                       | `10`                 |
| `service.type`                    | Service type                                                                   | `ClusterIP`          |
| `service.annotations`             | Additional annotations for the vaultwarden service                             | `{}`                 |
| `service.labels`                  | Additional labels for the service                                              | `{}`                 |
| `service.ipFamilyPolicy`          | IP family policy for the service                                               | `SingleStack`        |
| `ingress.enabled`                 | Deploy an ingress resource.                                                    | `false`              |
| `ingress.class`                   | Ingress resource class                                                         | `nginx`              |
| `ingress.nginxIngressAnnotations` | Add nginx specific ingress annotations                                         | `true`               |
| `ingress.additionalAnnotations`   | Additional annotations for the ingress resource.                               | `{}`                 |
| `ingress.labels`                  | Additional labels for the ingress resource.                                    | `{}`                 |
| `ingress.tls`                     | Enable TLS on the ingress resource.                                            | `true`               |
| `ingress.hostname`                | Hostname for the ingress.                                                      | `warden.contoso.com` |
| `ingress.additionalHostnames`     | Additional hostnames for the ingress.                                          | `[]`                 |
| `ingress.path`                    | Default application path for the ingress                                       | `/`                  |
| `ingress.pathType`                | Path type for the ingress                                                      | `Prefix`             |
| `ingress.tlsSecret`               | Kubernetes secret containing the SSL certificate when using the "nginx" class. | `""`                 |
| `ingress.nginxAllowList`          | Comma-separated list of IP addresses and subnets to allow.                     | `""`                 |
| `ingress.customHeadersConfigMap`  | ConfigMap containing custom headers to be added to the ingress.                | `{}`                 |
