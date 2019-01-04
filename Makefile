SHELL := /bin/bash

GITHUB_SSH_KEY ?= $(HOME)/.ssh/id_rsa

NRO ?= $(shell cat NRO | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr ' ' '-')
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

DEFAULT_GOAL: all


.PHONY: all
all: test prompt init env deploy done

.PHONY: test
test:
	env | sort

.PHONY: prompt
prompt:
	@prompt.sh

################################################################################

.PHONY: init
init: init-repo init-project init-db init-bucket

.PHONY: init-repo
init-repo:
	init_github_repo.sh

.PHONY: init-project
init-project:
	init_circle_project.sh

.PHONY: init-db
init-db:
	init_db.sh

.PHONY: init-bucket
init-bucket:
	init_bucket.sh

################################################################################
.PHONY: env
env: env-ci env-wp

.PHONY: env-ci
env-ci:
	init_ci_secrets.sh

.PHONY: env-wp
env-wp:
	init_wp_environment.sh

################################################################################

.PHONY: delete-yes-i-mean-it
delete-yes-i-mean-it:	delete-repo-yes-i-mean-it delete-db-yes-i-mean-it delete-bucket-yes-i-mean-it

.PHONY: delete-repo-yes-i-mean-it
delete-repo-yes-i-mean-it:
	delete_github_repo.sh

.PHONY: delete-db-yes-i-mean-it
delete-db-yes-i-mean-it:
	delete_db.sh

.PHONY: delete-bucket-yes-i-mean-it
delete-bucket-yes-i-mean-it:
	delete_bucket.sh

################################################################################

.PHONY: deploy
deploy:
	trigger_build.sh


################################################################################

.PHONY:
post-install: helper post-install-nginx post-install-ga-login post-install-update-links

helper:
	git clone https://github.com/greenpeace/planet4-helper-scripts helper

.PHONY: post-install-nginx
post-install-nginx:
	make -C helper nginx-helper

.PHONY: post-install-ga-login
post-install-ga-login:
	make -C helper ga-login

.PHONY: post-install-update-links
post-install-update-links:
	make -C helper update-links

################################################################################

.PHONY: init-service-account
init-service-account:
	init_service_account.sh

.PHONY: delete-service-account-yes-i-mean-it
delete-service-account-yes-i-mean-it:
	delete_service_account.sh

################################################################################

.PHONY: done
done:
	@echo "@todo: Add user key for read/write operations"
	@echo "Visit https://circleci.com/gh/greenpeace/$(CONTAINER_PREFIX)/edit#checkout"
	@echo

.PHONY: run
run:
	docker build -t p4-build .
	docker run --rm -ti \
		--name p4-nro-generator \
		-e "NRO=$(NRO)" \
		-e "SERVICE_ACCOUNT_NAME=$(SERVICE_ACCOUNT_NAME)" \
		-v "$(GITHUB_SSH_KEY):/root/.ssh/id_rsa" \
		-v "$(PWD)/secrets:/app/secrets" \
		p4-build make $(RUN_ARGS)

.PHONY: run-circleci
run-circleci:
	docker build -t p4-build .
	docker run --rm -i \
		--name p4-nro-generator \
		-e "NRO=$(NRO)" \
		-e "SERVICE_ACCOUNT_NAME=$(SERVICE_ACCOUNT_NAME)" \
		p4-build make $(RUN_CIRCLECI_ARGS)
