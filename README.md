# Helm chart for Vaultwarden

[![MIT Licensed](https://img.shields.io/github/license/guerzon/vaultwarden)](https://github.com/guerzon/vaultwarden/blob/main/LICENSE)
[![Artifact Hub](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/vaultwarden)](https://artifacthub.io/packages/search?repo=vaultwarden)

[Vaultwarden](https://github.com/dani-garcia/vaultwarden), formerly known as **Bitwarden_RS**, is an "alternative implementation of the Bitwarden server API written in Rust and compatible with [upstream Bitwarden clients](https://bitwarden.com/download/), perfect for self-hosted deployment where running the official resource-heavy service might not be ideal."

## Description

This [Helm](https://helm.sh/docs/) chart is used to deploy `vaultwarden` with a stable configuration to Kubernetes clusters.

The `vaultwarden` project can be found [here](https://github.com/dani-garcia/vaultwarden). To learn more about Vaultwarden, please visit the [wiki](https://github.com/dani-garcia/vaultwarden/wiki).

### Change of Resource Type in Versions >= 0.18.0

Starting from version 0.18.0, when a stateless configuration is detected that utilizes an external database and persistent storage, a `Deployment` is automatically used in favor of the current `StatefulSet`. This enables running multiple pods simultaneously, thereby enhancing the processes of updates, rollbacks, and scalability for load balancing. This automatic detection can be overridden by manually specifying a `resourceType`.

## Prerequisites

- Kubernetes >= 1.12
- Helm >= 3.1.0
- `docker` and `make` for generating the chart documentation

## Usage

Add the repository:

```bash
helm repo add vaultwarden https://guerzon.github.io/vaultwarden
```

Refer to the detailed documentation [here](./charts/vaultwarden/README.md).

## Disclaimer

Please do your due-diligence before using this chart for a production deployment.

Nevertheless, if you find any issues while using this chart, or have any suggestions, I would appreciate it if you would [submit an issue](https://github.com/guerzon/vaultwarden/issues/new). Alternatively, PRs are appreciated!

## License

See [LICENSE](./LICENSE).

## Author

This Helm chart was created and maintained by [Lester Guerzon](https://blog.pidnull.io).

### Credits

- The `vaultwarden` project can be found [here](https://github.com/dani-garcia/vaultwarden)
- Further information about `Bitwarden` and 8bit Solutions LLC can be found [here](https://bitwarden.com/)

## References

- Guides: <https://github.com/dani-garcia/vaultwarden/wiki>
- Configuration: <https://github.com/dani-garcia/vaultwarden/blob/main/.env.template>
- Releases: <https://github.com/dani-garcia/vaultwarden/releases>
