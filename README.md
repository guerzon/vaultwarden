# vaultwarden-helm

[vaultwarden](https://github.com/dani-garcia/vaultwarden), formerly known as **Bitwarden_RS**, is an alternative implementation of the Bitwarden server API in Rust, including the Web Vault.

## Intro

### TL;DR

```bash
git clone https://github.com/guerzon/vaultwarden
cd vaultwarden
helm install my-vaultwarden-release .
```

### Background

In 2020, I built a simple project for deploying **Bitwarden_RS** to Kubernetes, which can be found [here](https://github.com/guerzon/bitwarden-kubernetes). That project is made up of various YAML files which have to be edited manually when adding required customizations.

The aim of this project is to deploy `vaultwarden` with a stable configuration to Kubernetes clusters using [Helm](https://helm.sh/docs/).

The upstream repository for the `vaultwarden` project can be found [here](https://github.com/dani-garcia/vaultwarden).

### Word of caution

I initially built this Helm chart for the purposes of learning Helm chart development, Kubernetes, and in general managing application releases using Helm.

Thus, I cannot guarantee quality. Nevertheless, if you find any issues while using this chart, or have any suggestions, feel free to submit an issue.

## Prerequisites

- Kubernetes 1.12+
- Helm 3.1.0

## Usage

To install the chart with the release name `vaultwarden-release`:

```bash
export NAMESPACE=vaultwarden
export DOMAIN_NAME=pass.company.com
helm install vaultwarden-release . \
  --namespace $NAMESPACE \
  --set "ingress.enabled=true" \
  --set "ingress.hostname=$DOMAIN_NAME"
```

To install the chart in another namespace using custom values in the file `demo-values.yaml`:

```bash
export NAMESPACE=vaultwarden-demo
export RELEASE_NAME=vaultwarden-demo
helm upgrade -i \
  -n $NAMESPACE $RELEASE_NAME . \
  -f demo-values.yaml
```

### SSL and Ingress

This chart supports the usage of existing Ingress Controllers, such as [ingress-nginx](https://github.com/kubernetes/ingress-nginx/) and certificates stored as Kubernets secrets.

Nginx ingress controller can be installed by following [this](https://kubernetes.github.io/ingress-nginx/deploy/) guide.

An SSL certificate can be added as a secret with a few commands:

```bash
cd <dir-containing-the-certs>
kubectl create secret -n vaultwarden \
  tls vaultwarden-ssl-cert \
  --key privkey.pem \
  --cert fullchain.pem
```

Once both prerequisites are ready, a custom `values.yml` can be set as follows:

```yaml
ingress:
  enabled: true
  tls: true
  hostname: vaultwarden.example.com
  tlsSecret: vaultwarden-ssl-cert
```

Complete configuration options can be found [below](#exposure-parameters).

### Security options

Admin token: `openssl rand -base64 48`

### Mail settings

To enable the SMTP service, make sure that at the minimum, `smtp.host` and `smtp.from` are set.

## Uninstalling the Chart

To uninstall/delete the `vaultwarden-demo` release:

```console
export RELEASE_NAME=vaultwarden-demo
helm uninstall $RELEASE_NAME
```

## Parameters

### General settings

| Name                    | Description                                   | Value               |
| ----------------------- | --------------------------------------------- | ------------------- |
| `vaultVersion`          | vaultwarden version to deploy.                | `1.24.0`            |
| `domain`                | Domain name where the application is accessed | `""`                |
| `adminToken`            | The admin token                               | `R@ndomToken$tring` |
| `fullnameOverride`      | String to override the application name.      | `""`                |
| `websocket.enabled`     | Enable websocket notifications                | `true`              |
| `websocket.address`     | Websocket listen address                      | `0.0.0.0`           |
| `websocket.port`        | Websocket listen port                         | `3012`              |
| `serviceAccount.create` | Create a service account                      | `true`              |
| `serviceAccount.name`   | Name of the service account to create         | `vaultwarden-svc`   |


### Exposure parameters

| Name                  | Description                                                | Value                    |
| --------------------- | ---------------------------------------------------------- | ------------------------ |
| `ingress.enabled`     | Deploy an ingress resource.                                | `false`                  |
| `ingress.class`       | Ingress class                                              | `nginx`                  |
| `ingress.tls`         | Enable TLS on the ingress resource.                        | `true`                   |
| `ingress.hostname`    | Hostname for the ingress.                                  | `warden.contoso.com`     |
| `ingress.path`        | Default application path for the ingress                   | `/`                      |
| `ingress.pathWs`      | Path for the websocket ingress                             | `/notifications/hub`     |
| `ingress.pathType`    | Path type for the ingress                                  | `ImplementationSpecific` |
| `ingress.pathTypeWs`  | Path type for the ingress                                  | `ImplementationSpecific` |
| `ingress.tlsSecret`   | Kubernetes secret containing the SSL certificate.          | `""`                     |
| `ingress.allowList`   | Comma-separated list of IP addresses and subnets to allow. | `""`                     |
| `service.type`        | Service type                                               | `ClusterIP`              |
| `service.annotations` | Additional annotations for the vaultwarden service         | `{}`                     |


### SMTP configuration

| Name                 | Description                           | Value      |
| -------------------- | ------------------------------------- | ---------- |
| `smtp.host`          | SMTP host                             | `""`       |
| `smtp.security`      | SMTP Encryption method                | `starttls` |
| `smtp.port`          | SMTP port                             | `25`       |
| `smtp.from`          | SMTP sender email address             | `""`       |
| `smtp.fromName`      | SMTP sender FROM                      | `""`       |
| `smtp.username`      | Username for the SMTP authentication. | `""`       |
| `smtp.password`      | Password for the SMTP service.        | `""`       |
| `smtp.authMechanism` | SMTP authentication mechanism         | `Plain`    |
| `smtp.debug`         | SMTP debugging                        | `false`    |


## License

[MIT](./LICENSE).

## Author

This Helm chart was created and is being maintained by [Lester Guerzon](https://pidnull.io).
