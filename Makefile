help:
	@echo "Available targets:"
	@echo "  lint           - Run all linting checks (includes ct lint)"
	@echo "  test           - Run all tests (lightweight + chart-testing install)"
	@echo "  test-local     - Run lightweight tests"
	@echo "  test-schema    - Validate chart against values.schema.json"
	@echo "  ct-lint        - Run chart-testing lint"
	@echo "  ct-install     - Run chart-testing install (requires Kubernetes)"

lint: ct-lint
	@echo "Linting passed"

test: test-local ct-install
	@echo "All tests passed"

test-local:
	bash test-chart.sh

test-schema:
	helm lint charts/vaultwarden

ct-lint:
	ct lint --target-branch main

ct-install:
	ct install --target-branch main

.PHONY: help lint test test-local test-schema ct-lint ct-install