SHELL := /bin/bash

################################################################################
# Ensure these files exist, or that the keys are in environment

WP_STATELESS_KEY        := $(shell cat secrets/stateless-service-account.json | base64 -w 0 | xargs)
SQLPROXY_KEY            := $(shell cat secrets/cloudsql-service-account.json | base64 -w 0 | xargs)

###############################################################################


DEFAULT_GOAL: all

all: clean init env deploy

clean:
	rm -fr src

################################################################################

init: init-repo init-project

init-repo:
	./init_github_repo.sh

init-project:
	./init_circle_project.sh

###############################################################################

env: env-stateless env-sqlproxy env-wp

env-stateless:
	./add_environment_variable.sh WP_STATELESS_KEY $(WP_STATELESS_KEY)

env-sqlproxy:
	./add_environment_variable.sh SQLPROXY_KEY $(WP_STATELESS_KEY)

env-wp:
	./generate_wp_keys.sh

################################################################################

delete-yes-i-mean-it: delete-repo-yes-i-mean-it delete-project-yes-i-mean-it

delete-repo-yes-i-mean-it:
	./delete_github_repo.sh

delete-project-yes-i-mean-it:

################################################################################

deploy:
	./trigger_build.sh
