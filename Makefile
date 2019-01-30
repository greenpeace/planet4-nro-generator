SHELL := /bin/bash

# Use default SSH key if not set
GITHUB_SSH_KEY ?= $(HOME)/.ssh/id_rsa

# convert NRO name to lowercase, remove punctuation, replace space with hyphen
NRO ?= $(shell cat NRO_NAME | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr ' ' '-')
ifeq ($(strip $(NRO)),)
$(error NRO name not set, please run ./configure.sh)
endif

SERVICE_ACCOUNT_NAME ?= $(shell cat SERVICE_ACCOUNT_NAME)

ifeq ("$(wildcard secrets/service-accounts/$(SERVICE_ACCOUNT_NAME).json)","")
$(error Service account file not found: secrets/service-accounts/$(SERVICE_ACCOUNT_NAME).json)
endif

include secrets/common
export $(shell sed 's/=.*//' secrets/common)
include secrets/env.$(NRO)
export $(shell sed 's/=.*//' secrets/env.$(NRO))

# If the first argument is "run"...
ifeq (run,$(firstword $(MAKECMDGOALS)))
# use the rest as arguments for "run"
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
# ...and turn them into do-nothing targets
$(eval $(RUN_ARGS):;@:)
endif

# If the first argument is "run-circleci"...
ifeq (run-circleci,$(firstword $(MAKECMDGOALS)))
# use the rest as arguments for "run"
RUN_CIRCLECI_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
# ...and turn them into do-nothing targets
$(eval $(RUN_CIRCLECI_ARGS):;@:)
endif

###############################################################################

.DEFAULT_GOAL := run

lint: lint-sh

lint-sh:
	find . -type f -name '*.sh' | xargs shellcheck

.PHONY: run
run: lint
	docker build -t p4-build .
	docker run --rm -ti \
		--name p4-nro-generator \
		-e "NRO=$(NRO)" \
		-e "SERVICE_ACCOUNT_NAME=$(SERVICE_ACCOUNT_NAME)" \
		-v "$(GITHUB_SSH_KEY):/root/.ssh/id_rsa" \
		-v "$(PWD)/secrets:/app/secrets" \
		p4-build make -f Makefile-run $(RUN_ARGS)

.PHONY: run-circleci
run-circleci: lint
	docker build -t p4-build .
	docker run --rm -i \
		--name p4-nro-generator \
		-e "NRO=$(NRO)" \
		-e "SERVICE_ACCOUNT_NAME=$(SERVICE_ACCOUNT_NAME)" \
		p4-build make -f Makefile-run $(RUN_CIRCLECI_ARGS)
