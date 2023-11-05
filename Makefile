
lint:
	ct lint --target-branch main

test:
	ct install --target-branch main --helm-extra-set-args="--set=domain=https://warden.example.com:8443"

.PHONY: lint test
