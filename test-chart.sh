#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHART_DIR="${SCRIPT_DIR}/charts/vaultwarden"
TEST_VALUES="${CHART_DIR}/ci/test-values.yaml"

echo "[+] Testing with helm lint ..."
helm template "${CHART_DIR}" -f "${TEST_VALUES}" > /dev/null
helm lint "${CHART_DIR}"

# Optional: validate with kubeconform if installed
if command -v kubeconform >/dev/null 2>&1; then
  echo "[+] Testing with kubeconform ..."
  helm template "${CHART_DIR}" -f "${TEST_VALUES}" | kubeconform --strict
fi

if command -v yamllint >/dev/null 2>&1; then
  echo "[+] Testing with yamllint ..."
  yamllint -c "${SCRIPT_DIR}/lintconf.yaml" "${CHART_DIR}"/values.yaml "${CHART_DIR}"/Chart.yaml
fi
