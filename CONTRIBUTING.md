
# Contributing Guide

## Certificate of Origin

By contributing to this project you agree to the Developer Certificate of Origin [DCO](../DCO).

This document was created by the Linux Kernel community and is a simple statement that you, as a contributor, have the legal right to make the contribution.

See the [DCO](../DCO) file for details.

## How-to

1. Fork this repository, develop, and test your changes.
2. When updating the `values.yml`, also update the [chart documentation](./charts/vaultwarden/README.md) by using [this tool](https://github.com/bitnami-labs/readme-generator-for-helm). A quick way to do this is to run the tool via Docker and the script [generate-readme.sh](generate-readme.sh):

    ```bash
    ./generate-readme.sh
    ```

3. Submit a pull request.

### Reminders

When submitting a pull request, please ensure that:

- The PR follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles.
