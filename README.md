# Helm chart for Vaultwarden

[![MIT Licensed](https://img.shields.io/github/license/guerzon/vaultwarden)](https://github.com/guerzon/vaultwarden/blob/main/LICENSE)
[![Helm Release](https://img.shields.io/docker/v/vaultwarden/server/1.24.0)](https://img.shields.io/docker/v/vaultwarden/server/1.24.0)

[Vaultwarden](https://github.com/dani-garcia/vaultwarden), formerly known as **Bitwarden_RS**, is an "alternative implementation of the Bitwarden server API written in Rust and compatible with [upstream Bitwarden clients](https://bitwarden.com/download/), perfect for self-hosted deployment where running the official resource-heavy service might not be ideal."

## TL;DR

```bash
git clone https://github.com/guerzon/vaultwarden
cd vaultwarden
helm install my-vaultwarden-release .
```

## Description

### Short intro

In 2020, I built a simple project for deploying **Bitwarden_RS** to Kubernetes, which can be found [here](https://github.com/guerzon/bitwarden-kubernetes). That project is made up of various YAML files which have to be edited manually when adding required customizations.

The aim of this project is to deploy `vaultwarden` with a stable configuration to Kubernetes clusters using [Helm](https://helm.sh/docs/).

The upstream repository for the `vaultwarden` project can be found [here](https://github.com/dani-garcia/vaultwarden).

To learn more about Vaultwarden, please visit the [wiki](https://github.com/dani-garcia/vaultwarden/wiki).

## Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0

## Usage

To deploy the chart with the release name `vaultwarden-release`:

```bash
export NAMESPACE=vaultwarden
export DOMAIN_NAME=pass.company.com
helm install vaultwarden-release . \
  --namespace $NAMESPACE \
  --set "ingress.enabled=true" \
  --set "ingress.hostname=$DOMAIN_NAME"
```

To deploy the chart to another namespace using custom values in the file `demo.yaml`:

```bash
export NAMESPACE=vaultwarden-demo
export RELEASE_NAME=vaultwarden-demo
helm upgrade -i \
  -n $NAMESPACE $RELEASE_NAME . \
  -f demo.yaml
```

### General configuration

This chart deploys `vaultwarden` from pre-built images on [Docker Hub](https://hub.docker.com/r/vaultwarden/server/tags): `vaultwarden/server`. The image can be defined by specifying the tag with `image.tag`.

Example that uses the Alpine-based image `1.24.0-alpine` and an existing secret that contains registry credentials:

```yaml
image:
  tag: "1.24.0-alpine"
  pullSecrets:
    - myRegKey
```

**Important**: specify the URL used by users with the `domain` variable, otherwise, some functionalities might not work:

```yaml
domain: "https://vaultwarden.contoso.com:9443/"
```

Detailed configuration options can be found in the [Vaultwarden settings](#vaultwarden-settings) section below.

### Database options

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

Detailed configuration options can be found in the [Database Configuration](#database-configuration) section below.

### SSL and Ingress

This chart supports the usage of existing Ingress Controllers for exposing the `vaultwarden` deployment.

#### nginx-ingress

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

#### AWS LB Controller

When using AWS, the [AWS Load Balancer controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/deploy/installation/) can be used together with [ACM](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/ingress/cert_discovery/).

Example for AWS:

```yaml
ingress:
  enabled: true
  class: "alb"
  hostname: vaultwarden.contoso.com
  additionalAnnotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/tags: Environment=dev,Team=test
    alb.ingress.kubernetes.io/certificate-arn: "arn:aws:acm:eu-central-1:ACCOUNT:certificate/LONGID"
```

Detailed configuration options can be found in the [Exposure Parameters](#exposure-parameters) section below.

### Security

An admin token can be generated with: `openssl rand -base64 48`.

Detailed configuration options can be found in the [Security Settings](#security-settings) section below.

By default, the chart deploys a [service account](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/) called `vaultwarden-svc`.

```yaml
serviceAccount:
  create: true
  name: "vaultwarden-svc"
```

Detailed configuration options can be found in the [Security settings](#security-settings) section below.

### Mail settings

To enable the SMTP service, make sure that at a minimum, `smtp.host` and `smtp.from` are set.

```yaml
smtp:
  host: mx01.contoso.com
  from: no-reply@contoso.com
  fromName: "Vault Administrator"
  username: admin
  password: password
  acceptInvalidHostnames: "true"
  acceptInvalidCerts: "true"
```

Detailed configuration options can be found in the [SMTP Configuration](#smtp-configuration) section below.

### Storage

To use persistent storage using a claim, set `storage.enabled` to `true`. The following example sets the storage class to an already-installed Rancher's [local path storage](https://github.com/rancher/local-path-provisioner) provisioner.

```yaml
storage:
  enabled: true
  size: "10Gi"
  class: "local-path"
```

Example for AWS:

```yaml
storage:
  enabled: true
  size: "10Gi"
  class: "gp2"
```

Detailed configuration options can be found in the [Storage Configuration](#storage-configuration) section below.


## Parameters

### Vaultwarden settings

| Name                | Description                                   | Value                |
| ------------------- | --------------------------------------------- | -------------------- |
| `image.registry`    | Vaultwarden image registry                    | `docker.io`          |
| `image.repository`  | Vaultwarden image repository                  | `vaultwarden/server` |
| `image.tag`         | Vaultwarden image tag                         | `1.24.0`             |
| `image.pullPolicy`  | Vaultwarden image pull policy                 | `IfNotPresent`       |
| `image.pullSecrets` | Specify docker-registry secret names          | `[]`                 |
| `domain`            | Domain name where the application is accessed | `""`                 |
| `websocket.enabled` | Enable websocket notifications                | `true`               |
| `websocket.address` | Websocket listen address                      | `0.0.0.0`            |
| `websocket.port`    | Websocket listen port                         | `3012`               |
| `rocket.port`       | Rocket port                                   | `8080`               |
| `rocket.workers`    | Rocket number of workers                      | `10`                 |
| `webVaultEnabled`   | Enable Web Vault                              | `true`               |

### Security settings

| Name                    | Description                                                                     | Value               |
| ----------------------- | ------------------------------------------------------------------------------- | ------------------- |
| `adminToken`            | The admin token used for /admin                                                 | `R@ndomToken$tring` |
| `signupsAllowed`        | By default, anyone who can access your instance can register for a new account. | `true`              |
| `invitationsAllowed`    | Even when registration is disabled, organization administrators or owners can   | `true`              |
| `signupDomains`         | List of domain names for users allowed to register                              | `contoso.com`       |
| `signupsVerify`         | Whether to require account verification for newly-registered users.             | `true`              |
| `showPassHint`          | Whether a password hint should be shown in the page.                            | `false`             |
| `fullnameOverride`      | String to override the application name.                                        | `""`                |
| `serviceAccount.create` | Create a service account                                                        | `true`              |
| `serviceAccount.name`   | Name of the service account to create                                           | `vaultwarden-svc`   |

### Exposure Parameters

| Name                              | Description                                                                    | Value                    |
| --------------------------------- | ------------------------------------------------------------------------------ | ------------------------ |
| `ingress.enabled`                 | Deploy an ingress resource.                                                    | `false`                  |
| `ingress.class`                   | Ingress resource class                                                         | `nginx`                  |
| `ingress.nginxIngressAnnotations` | Add nginx specific ingress annotations                                         | `true`                   |
| `ingress.additionalAnnotations`   | Additional annotations for the ingress resource.                               | `{}`                     |
| `ingress.tls`                     | Enable TLS on the ingress resource.                                            | `true`                   |
| `ingress.hostname`                | Hostname for the ingress.                                                      | `warden.contoso.com`     |
| `ingress.path`                    | Default application path for the ingress                                       | `/`                      |
| `ingress.pathWs`                  | Path for the websocket ingress                                                 | `/notifications/hub`     |
| `ingress.pathType`                | Path type for the ingress                                                      | `ImplementationSpecific` |
| `ingress.pathTypeWs`              | Path type for the ingress                                                      | `ImplementationSpecific` |
| `ingress.tlsSecret`               | Kubernetes secret containing the SSL certificate when using the "nginx" class. | `""`                     |
| `ingress.nginxAllowList`          | Comma-separated list of IP addresses and subnets to allow.                     | `""`                     |
| `service.type`                    | Service type                                                                   | `ClusterIP`              |
| `service.annotations`             | Additional annotations for the vaultwarden service                             | `{}`                     |

### Database Configuration

| Name                   | Description                               | Value     |
| ---------------------- | ----------------------------------------- | --------- |
| `database.type`        | Database type, either mysql or postgresql | `default` |
| `database.host`        | Database hostname or IP address           | `""`      |
| `database.port`        | Database port                             | `""`      |
| `database.username`    | Database username                         | `""`      |
| `database.password`    | Database password                         | `""`      |
| `database.dbName`      | Database name                             | `""`      |
| `database.uriOverride` | Manually specify the DB connection string | `""`      |

### SMTP Configuration

| Name                          | Description                           | Value      |
| ----------------------------- | ------------------------------------- | ---------- |
| `smtp.host`                   | SMTP host                             | `""`       |
| `smtp.security`               | SMTP Encryption method                | `starttls` |
| `smtp.port`                   | SMTP port                             | `25`       |
| `smtp.from`                   | SMTP sender email address             | `""`       |
| `smtp.fromName`               | SMTP sender FROM                      | `""`       |
| `smtp.username`               | Username for the SMTP authentication. | `""`       |
| `smtp.password`               | Password for the SMTP service.        | `""`       |
| `smtp.authMechanism`          | SMTP authentication mechanism         | `Plain`    |
| `smtp.acceptInvalidHostnames` | Accept Invalid Hostnames              | `false`    |
| `smtp.acceptInvalidCerts`     | Accept Invalid Certificates           | `false`    |
| `smtp.debug`                  | SMTP debugging                        | `false`    |

### Storage Configuration

| Name              | Description                                 | Value     |
| ----------------- | ------------------------------------------- | --------- |
| `storage.enabled` | Enable configuration for persistent storage | `false`   |
| `storage.size`    | Storage size for /data                      | `15Gi`    |
| `storage.class`   | Specify the storage class                   | `default` |
| `storage.dataDir` | Specify the data directory                  | `/data`   |

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

| Name             | Description                                                     | Value |
| ---------------- | --------------------------------------------------------------- | ----- |
| `nodeSelector`   | Node labels for pod assignment                                  | `{}`  |
| `tolerations`    | Tolerations for pod assignment                                  | `[]`  |
| `affinity`       | Affinity for pod assignment                                     | `{}`  |

## Uninstall

To uninstall/delete the `vaultwarden-demo` release:

```console
export NAMESPACE=vaultwarden
export RELEASE_NAME=vaultwarden-demo
helm -n $NAMESPACE uninstall $RELEASE_NAME
```

## Notes

I initially built this Helm chart for the purposes of learning Helm chart development, brush up on my Kubernetes skills, and in general, learn how to better manage application releases in Kubernetes.

Thus, I have to mention that this chart has to be tested more thoroughly before it is used in a production environment.

Nevertheless, if you find any issues while using this chart, or have any suggestions, I would appreciate it if you would [submit an issue](https://github.com/guerzon/vaultwarden/issues/new).

### Todo

1. Implement more configuration options.
2. Prometheus metrics scraping would be nice to have.
3. Automated testing, CI

## License

[MIT](./LICENSE).

## Author

This Helm chart was created and is being maintained by [Lester Guerzon](https://pidnull.io).

### Credits

- The `vaultwarden` project can be found [here](https://github.com/dani-garcia/vaultwarden)
- Further information about `Bitwarden` and 8bit Solutions LLC can be found [here](https://bitwarden.com/)
