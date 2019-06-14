SHELL := /bin/bash

# Use default SSH key if not set
GITHUB_SSH_KEY ?= ~/.ssh/id_rsa

# convert NRO name to lowercase, remove punctuation, replace space with hyphen

ifneq ($(wildcard NRO_NAME),)
NRO ?= $(shell cat NRO_NAME | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr ' ' '-')
endif

ifneq ($(wildcard secrets/common),)
include secrets/common
export $(shell sed 's/=.*//' secrets/common)
endif

ifneq ($(wildcard secrets/env.$(NRO)),)
include secrets/env.$(NRO)
export $(shell sed 's/=.*//' secrets/env.$(NRO))
endif

SERVICE_ACCOUNT_NAME ?= $(shell cat SERVICE_ACCOUNT_NAME)

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

# ---

# Check necessary commands exist

DOCKER := $(shell command -v docker 2> /dev/null)
SHELLCHECK := $(shell command -v shellcheck 2> /dev/null)

###############################################################################

.DEFAULT_GOAL := run

clean:
	rm -f NRO_NAME
	rm -f SERVICE_ACCOUNT_NAME

.git/hooks/pre-commit:
	@chmod 755 .githooks/*
	@find .git/hooks -type l -exec rm {} \;
	@find .githooks -type f -exec ln -sf ../../{} .git/hooks/ \;

lint:
	@$(MAKE) -j .git/hooks/pre-commit lint-sh lint-docker

lint-sh:
ifndef SHELLCHECK
	$(error "shellcheck is not installed: https://github.com/koalaman/shellcheck")
endif
		@find . -type f -name '*.sh' | xargs $(SHELLCHECK) -x

lint-docker:
ifndef DOCKER
	$(error "docker is not installed: https://docs.docker.com/install/")
endif
		@docker run --rm -i hadolint/hadolint < Dockerfile

pull:
	docker pull gcr.io/planet-4-151612/ubuntu:latest

NRO_NAME:
	./configure.sh

.PHONY: run
run: NRO_NAME
ifndef NRO
	$(error NRO name not set, please run ./configure.sh)
endif
ifndef SERVICE_ACCOUNT_NAME
	$(error SERVICE_ACCOUNT_NAME name not set, please run ./configure.sh)
endif
	docker build -t p4-build .
	docker run --rm -ti \
		--name p4-nro-generator \
		-e "NRO=$(NRO)" \
		-e "SERVICE_ACCOUNT_NAME=$(SERVICE_ACCOUNT_NAME)" \
		-v "$(GITHUB_SSH_KEY):/tmp/.ssh/id_rsa" \
		-v "$(PWD)/secrets:/app/secrets" \
		p4-build make -f Makefile-run $(RUN_ARGS)

.PHONY: run-circleci
run-circleci: NRO_NAME
ifndef NRO
	$(error NRO name not set, please run ./configure.sh)
endif
ifndef SERVICE_ACCOUNT_NAME
	$(error SERVICE_ACCOUNT_NAME name not set, please run ./configure.sh)
endif
	docker build -t p4-build .
	docker run --rm -i \
		--name p4-nro-generator \
		-e "NRO=$(NRO)" \
		-e "SERVICE_ACCOUNT_NAME=$(SERVICE_ACCOUNT_NAME)" \
		p4-build make -f Makefile-run $(RUN_CIRCLECI_ARGS)
