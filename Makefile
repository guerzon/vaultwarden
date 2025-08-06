
lint:
	ct lint --target-branch main

test:
	ct install --target-branch main

.PHONY: lint test
