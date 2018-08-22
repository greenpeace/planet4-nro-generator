SHELL := /bin/bash

NRO ?= $(shell cat NRO | tr '[:upper:]' '[:lower:]' | tr -d '[:punct:]' | tr ' ' '-')
ifeq ($(strip $(NRO)),)
$(error NRO name not set, please run ./configure.sh)
endif

ifeq ("$(wildcard secrets/service-accounts/$(NRO).json)","")
$(error Service account file not found: secrets/service-accounts/$(NRO).json)
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

.PHONY:
post-install: helper post-install-nginx post-install

helper:
	git clone https://github.com/greenpeace/planet4-helper-scripts helper

post-install-nginx:


.PHONY: run
run:
	docker build -t p4-build .
	docker run --rm -ti \
		--name p4-nro-generator \
		-e "NRO=$(NRO)" \
		-v "$(HOME)/.ssh/id_rsa:/root/.ssh/id_rsa" \
		-v "$(PWD)/secrets:/app/secrets" \
		p4-build make $(RUN_ARGS)
