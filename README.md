# Planet 4 NRO Generator

## Requirements:

1. [Github SSH deploy key](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/) at `~/.ssh/id_rsa`
1. [Github OAUTH token](https://github.com/settings/tokens)
1. [CircleCI API token](https://circleci.com/account/api)
1. [gcloud](https://cloud.google.com/sdk/gcloud/) installed in $PATH
1. [dockerize](https://github.com/jwilder/dockerize/releases) installed in $PATH
1. `make` installed in $PATH

## Deploying a New Planet4 CI Pipeline

### Quickstart:

Where `${NRO}` is substituted for the NRO path, or slug ( eg: `international` for the site https://www.greenpeace.org/international/ ):

1.  `./configure.sh`
1.  `make run`

### Configure:

#### NRO Variables:
Variable                  | Default                             | Description
--------------------------|-------------------------------------|---------------------------------------------------------------------------
APP_HOSTPATH              |                                     | URL stub, eg: `/international`
CONTAINER_PREFIX          | `planet4-${NRO}`                    | Prefix to name containers in the Helm release
GITHUB_REPOSITORY_NAME    | `planet4-${NRO}`                    | GitHub repository name, eg: `planet4-international`
GITHUB_USER_EMAIL         | `$(git config --global user.email)` | Github email
GITHUB_USER_EMAIL         | `$(git config --global user.name)`  | Github username
MAKE_MASTER               | true                                | Creates production environment resources
MAKE_RELEASE              | true                                | Creates release environment resources
NEWRELIC_APPNAME          | `P4 ${NRO}`                         | Name of application in NewRelic monitoring
MYSQL_USERNAME            | `planet4-${NRO}`                    | CloudSQL username (will be created)
MYSQL_PASSWORD            | `(generated)`                       | CloudSQL password
NEWRELIC_APPNAME          | `P4 ${NRO}`                         | Name of application in NewRelic monitoring
STATELESS_BUCKET_LOCATION | us                                  | https://cloud.google.com/storage/docs/bucket-locations#available_locations

#### Common secrets:

Secret                          | Default | Description
--------------------------------|---------|-----------------------------------------------------------------
CIRCLE_TOKEN                    |         | CircleCI token: https://circleci.com/account/api
GITHUB_OAUTH_TOKEN              |         | Github personal access token: https://github.com/settings/tokens
MYSQL_PRODUCTION_ROOT_USER      |         | Production environment CloudSQL user with all privileges
MYSQL_PRODUCTION_ROOT_PASSWORD  |         | Production environment CloudSQL password
MYSQL_DEVELOPMENT_ROOT_USER     |         | Development environment CloudSQL user with all privileges
MYSQL_DEVELOPMENT_ROOT_PASSWORD |         | Develop environment CloudSQL password

### Deploy

```bash
# Simple:
make run

# Full command:
docker build -t p4-build .
docker run --rm -ti \
  --name p4-nro-generator \
  -e "NRO=${NRO}" \
  -v "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa" \
  -v "${PWD}/secrets:/app/secrets" \
  p4-build
```

If you don't have a github-ready deploy key at ~/.ssh/id_rsa you may deploy by changing the Makefile or running the long-form command above and changing the line `-v "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa"` accordingly.

## Deleting all associated resources

Pass the Makefile target as a command parameter, eg:

```bash
# Deletes all databases, buckets, repositories etc.
docker run --rm -ti \
  -v "$(PWD)/secrets:/app/secrets" \
  -v "$(HOME)/.ssh/id_rsa:/root/.ssh/id_rsa" \
  p4-build delete-yes-i-mean-it

# via Make
make run delete-yes-i-mean-it
```

Look in the Makefile for more commands you can pass to the container.
