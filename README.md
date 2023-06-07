# Helm chart for Vaultwarden

[![MIT Licensed](https://img.shields.io/github/license/guerzon/vaultwarden)](https://github.com/guerzon/vaultwarden/blob/main/LICENSE)
[![Helm Release](https://img.shields.io/docker/v/vaultwarden/server/1.28.1)](https://img.shields.io/docker/v/vaultwarden/server/1.28.1)

[Vaultwarden](https://github.com/dani-garcia/vaultwarden), formerly known as **Bitwarden_RS**, is an "alternative implementation of the Bitwarden server API written in Rust and compatible with [upstream Bitwarden clients](https://bitwarden.com/download/), perfect for self-hosted deployment where running the official resource-heavy service might not be ideal."

## TL;DR

```bash
git clone https://github.com/guerzon/vaultwarden
cd vaultwarden
helm install my-vaultwarden-release charts/vaultwarden/
```

## Description

This [Helm](https://helm.sh/docs/) chart is used to deploy `vaultwarden` with a stable configuration to Kubernetes clusters.

The upstream repository for the `vaultwarden` project can be found [here](https://github.com/dani-garcia/vaultwarden). To learn more about Vaultwarden, please visit the [wiki](https://github.com/dani-garcia/vaultwarden/wiki).

## Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0

## Usage

To deploy the chart with the release name `vaultwarden-release`:

```bash
export NAMESPACE=vaultwarden
export DOMAIN_NAME=pass.company.com
helm install vaultwarden-release charts/vaultwarden/ \
  --namespace $NAMESPACE \
  --set "ingress.enabled=true" \
  --set "ingress.hostname=$DOMAIN_NAME"
```

To deploy the chart to another namespace using custom values in the file `demo.yaml`:

```bash
export NAMESPACE=vaultwarden-demo
export RELEASE_NAME=vaultwarden-demo
helm upgrade -i \
  -n $NAMESPACE $RELEASE_NAME charts/vaultwarden/ \
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

Detailed configuration options can be found in the [Vaultwarden settings](./charts/vaultwarden/README.md#vaultwarden-settings) section.

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

Alternatively, you could create a Kubernetes secret containing the database URI:

```bash
DB_STRING_B64=$(echo -n 'postgresql://appuser:apppassword@pg.contoso.eu:5433/qualdb' | base64 -w 0)
kubectl -n vaultwarden create secret generic prod-db-creds --from-literal=secret-uri=$DB_STRING_B64
```

Then pass the name of the secret and the key to the chart:

```yaml
database:
  type: postgresql
  existingSecret: "prod-db-creds"
  existingSecretKey: "secret-uri"
```

Detailed configuration options can be found in the [Database Configuration](./charts/vaultwarden/README.md#database-configuration) section.

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

Detailed configuration options can be found in the [Exposure Parameters](./charts/vaultwarden/README.md#exposure-parameters) section.

### Security

An admin token can be generated with: `openssl rand -base64 48`.

By default, the chart deploys a [service account](https://kubernetes.io/docs/reference/access-authn-authz/service-accounts-admin/) called `vaultwarden-svc`.

```yaml
serviceAccount:
  create: true
  name: "vaultwarden-svc"
```

Detailed configuration options can be found in the [Security settings](./charts/vaultwarden/README.md#security-settings) section.

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

Detailed configuration options can be found in the [SMTP Configuration](./charts/vaultwarden/README.md#smtp-configuration) section.

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

Detailed configuration options can be found in the [Storage Configuration](./charts/vaultwarden/README.md#storage-configuration) section.

## Parameters

Refer to the detailed parameter documentation [here](./charts/vaultwarden/README.md).

## Uninstall

To uninstall/delete the `vaultwarden-demo` release:

```console
export NAMESPACE=vaultwarden
export RELEASE_NAME=vaultwarden-demo
helm -n $NAMESPACE uninstall $RELEASE_NAME
```

## Disclaimer

Please do your due-diligence before using this chart for a production deployment.

Nevertheless, if you find any issues while using this chart, or have any suggestions, I would appreciate it if you would [submit an issue](https://github.com/guerzon/vaultwarden/issues/new). Alternatively, PRs are appreciated!

## License

[MIT](./LICENSE).

## Author

This Helm chart was created and is being maintained by [Lester Guerzon](https://pidnull.io).

### Credits

- The `vaultwarden` project can be found [here](https://github.com/dani-garcia/vaultwarden)
- Further information about `Bitwarden` and 8bit Solutions LLC can be found [here](https://bitwarden.com/)
