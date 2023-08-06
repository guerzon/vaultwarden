
# Contributing Guide

## Requirements

1. Fork this repository, develop, and test your changes.
2. Submit a pull request.

### Technical Requirements

When submitting a pull request, please ensure that:

- The PR follows [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles.
- The tables of parameters are generated based on the metadata information from the `values.yaml` file, by using [this tool](https://github.com/bitnami-labs/readme-generator-for-helm).

  A quick way to do this is to run the tool via Docker and the script [generate-readme.sh](generate-readme.sh):

  ```bash
  ./generate-readme.sh
  ```
