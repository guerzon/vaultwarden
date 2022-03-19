
# Contributing Guide

## Requirements

1. Fork this repository, develop, and test your changes.
2. Submit a pull request.

### Technical Requirements

When submitting a PR make sure that it:

- The PR follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).

- Any change to a chart requires a version bump following [semver](https://semver.org/) principles.

- The tables of parameters are generated based on the metadata information from the `values.yaml` file, by using [this tool](https://github.com/bitnami-labs/readme-generator-for-helm).

  The easiest way to do this is to run the tool via Docker:

  ```bash
  # Clone and build:
  git clone https://github.com/bitnami-labs/readme-generator-for-helm
  cd readme-generator-for-helm/
  docker build -t readme-gen .

  # Run the tool and mount the current project directory.
  cd <this-project-dir>
  docker run --rm -d -it --name readmegen -v $(pwd):/mnt readme-gen bash
  docker exec -it readmegen bash
  ```
