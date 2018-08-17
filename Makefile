SHELL := /bin/bash

NRO := $(shell cat NRO | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr ' ' '-')
ifeq ($(strip $(NRO)),)
$(error NRO name not set, please run ./configure.sh)
endif

ifeq ("$(wildcard secrets/service-account/$(NRO).json)","")
$(error Service account file not found: secrets/service-account/$(NRO).json)
endif

include secrets/common
export $(shell sed 's/=.*//' secrets/common)
include secrets/env.$(NRO)
export $(shell sed 's/=.*//' secrets/env.$(NRO))

CONTINUE_ON_FAIL ?= false

# If the first argument is "run"...
ifeq (run,$(firstword $(MAKECMDGOALS)))
# use the rest as arguments for "run"
RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
# ...and turn them into do-nothing targets
$(eval $(RUN_ARGS):;@:)
endif

################################################################################
# Ensure these files exist, or that the keys are in environment

WP_STATELESS_KEY        := $(shell cat secrets/service-account/$(NRO).json | openssl base64 -A)
SQLPROXY_KEY            := $(WP_STATELESS_KEY)

###############################################################################

DEFAULT_GOAL: all


.PHONY: all
all: test prompt init env deploy

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
env: env-stateless env-sqlproxy env-wp

.PHONY: env-stateless
env-stateless:
	add_ci_env_var.sh WP_STATELESS_KEY "$(WP_STATELESS_KEY)"

.PHONY: env-sqlproxy
env-sqlproxy:
	add_ci_env_var.sh SQLPROXY_KEY "$(SQLPROXY_KEY)"

.PHONY: env-wp
env-wp:
	init_wp_environment.sh

################################################################################

.PHONY: delete-yes-i-mean-it
delete-yes-i-mean-it: delete-repo-yes-i-mean-it delete-project-yes-i-mean-it delete-db-yes-i-mean-it delete-bucket-yes-i-mean-it

.PHONY: delete-repo-yes-i-mean-it
delete-repo-yes-i-mean-it:
	delete_github_repo.sh

.PHONY: delete-project-yes-i-mean-it
delete-project-yes-i-mean-it:

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

.PHONY:
post-install: helper post-install-nginx post-install

helper:
	git clone https://github.com/greenpeace/planet4-helper-scripts helper

post-install-nginx:


.PHONY: run
run:
	docker build -t p4-build .
	CONTINUE_ON_FAIL=$(CONTINUE_ON_FAIL) \
	docker run --rm -ti \
		--name p4-nro-generator \
		-e "CONTINUE_ON_FAIL=$(CONTINUE_ON_FAIL)" \
		-v "$(HOME)/.ssh/id_rsa:/root/.ssh/id_rsa" \
		-v "$(PWD)/secrets:/app/secrets" \
		p4-build $(RUN_ARGS)
