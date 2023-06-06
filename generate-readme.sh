#!/usr/bin/env bash

# Clone and build:
if [ ! -d "readme-generator-for-helm" ]; then
    git clone https://github.com/bitnami-labs/readme-generator-for-helm
fi
cd readme-generator-for-helm/
docker build -t readme-gen .
cd ..

# Run the tool and mount the current project directory.
docker run --rm -v $(pwd):/mnt -w /mnt readme-gen readme-generator -v values.yaml -r README.md 
