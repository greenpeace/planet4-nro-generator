SHELL := /bin/bash

# If the first argument is "run"...
ifeq (run,$(firstword $(MAKECMDGOALS)))
  # use the rest as arguments for "run"
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  # ...and turn them into do-nothing targets
  $(eval $(RUN_ARGS):;@:)
endif

################################################################################
# Ensure these files exist, or that the keys are in environment

WP_STATELESS_KEY        := $(shell cat secrets/stateless-service-account.json | base64 -w 0)
SQLPROXY_KEY            := $(shell cat secrets/cloudsql-service-account.json | base64 -w 0)

###############################################################################

DEFAULT_GOAL: all

.PHONY: all
all: clean init env deploy

.PHONY: clean
clean:
	rm -fr src

################################################################################

.PHONY: init
init: init-repo init-project init-db

.PHONY: init-repo
init-repo:
	init_github_repo.sh

.PHONY: init-project
init-project:
	init_circle_project.sh

.PHONY: init-db
init-db:
	init_db.sh

################################################################################
.PHONY: env
env: env-stateless env-sqlproxy env-wp

.PHONY: env-stateless
env-stateless:
	add_environment_variable.sh WP_STATELESS_KEY "$(WP_STATELESS_KEY)"

.PHONY: env-sqlproxy
env-sqlproxy:
	add_environment_variable.sh SQLPROXY_KEY "$(SQLPROXY_KEY)"

.PHONY: env-wp
env-wp:
	init_wp_environment.sh

################################################################################

.PHONY: delete-yes-i-mean-it
delete-yes-i-mean-it: delete-repo-yes-i-mean-it delete-project-yes-i-mean-it delete-db-yes-i-mean-it

.PHONY: delete-repo-yes-i-mean-it
delete-repo-yes-i-mean-it:
	delete_github_repo.sh

.PHONY: delete-project-yes-i-mean-it
delete-project-yes-i-mean-it:

.PHONY: delete-db-yes-i-mean-it
delete-db-yes-i-mean-it:
	delete_db.sh

################################################################################

.PHONY: deploy
deploy:
	trigger_build.sh

.PHONY: run
run:
	docker build -t p4-build .
	CONTINUE_ON_FAIL=$(CONTINUE_ON_FAIL) \
	docker run --rm -ti \
	  -v "$(PWD)/secrets:/app/secrets" \
	  -v "$(HOME)/.ssh/id_rsa:/root/.ssh/id_rsa" \
	  p4-build $(RUN_ARGS)
