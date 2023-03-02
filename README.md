# Planet 4 NRO Generator

[Read this first](https://support.greenpeace.org/planet4/tech/nro-generation#create-the-environments)

## Requirements

1. [Github SSH deploy key](https://help.github.com/articles/generating-a-new-ssh-key-and-adding-it-to-the-ssh-agent/) at `~/.ssh/id_rsa`
2. [Github OAUTH token](https://github.com/settings/tokens)
3. [CircleCI API token](https://circleci.com/account/api)
4. [docker](https://docs.docker.com/install/) installed and running
5. [dockerize](https://github.com/jwilder/dockerize/releases) installed in $PATH
6. [gcloud](https://cloud.google.com/sdk/gcloud/) installed in $PATH
7. `make` installed in $PATH

## Dev Requirements

In addition to the above, you'll also need

1. [shellcheck](https://github.com/jwilder/dockerize/releases) installed in $PATH

## Creating a New Planet4 Instance

### Quickstart

#### Checklist

- Create an admin user on [dev](https://console.cloud.google.com/sql/instances/p4-develop-k8s/users?project=planet-4-151612) and [prod](https://console.cloud.google.com/sql/instances/planet4-prod/users?project=planet4-production) and put your credentials in `/secrets/common`. 
- Be sure that the circleci and github token also work.
- Run `gcloud auth list --format=json | jq -r '.[] | select(.account|test("^.+?@greenpeace.org")) | .account'` and check if the first account you see has iam access to the project.

Where `${NRO}` is substituted for the NRO path, or slug ( eg: `international` for the site <https://www.greenpeace.org/international/> ):

1. `./configure.sh`
2. `make run`
3. You may need to manually create an artifacts.yml file that replicates the environment variables section of the circleci configuration. This is used in the `bin/update_configs.sh` script when there are large changes made to the CI files. See [this](https://jira.greenpeace.org/browse/PLANET-6660) jira ticket for more information.

### Configure

#### NRO Variables

| Variable                  | Default                             | Description                                                                  |
| ------------------------- | ----------------------------------- | ---------------------------------------------------------------------------- |
| APP_HOSTPATH              |                                     | URL stub, eg: `/international`                                               |
| CONTAINER_PREFIX          | `planet4-${NRO}`                    | Prefix to name containers in the Helm release                                |
| GITHUB_REPOSITORY_NAME    | `planet4-${NRO}`                    | GitHub repository name, eg: `planet4-international`                          |
| GITHUB_SSH_KEY            | `${HOME}/.ssh/id_rsa`               | Path to GitHub SSH key                                                       |
| GITHUB_USER_EMAIL         | `$(git config --global user.email)` | Github email                                                                 |
| GITHUB_USER_NAME          | `$(git config --global user.name)`  | Github username                                                              |
| MAKE_MASTER               | true                                | Creates production environment resources                                     |
| MAKE_RELEASE              | true                                | Creates release environment resources                                        |
| MYSQL_PASSWORD            | `<generated>`                       | CloudSQL password                                                            |
| MYSQL_USERNAME            | `planet4-${NRO}`                    | CloudSQL username (will be created)                                          |
| STATELESS_BUCKET_LOCATION | us                                  | <https://cloud.google.com/storage/docs/bucket-locations#available_locations> |

#### Common secrets

| Secret                          | Default | Description                                                        |
| ------------------------------- | ------- | ------------------------------------------------------------------ |
| CIRCLE_TOKEN                    |         | CircleCI token: <https://circleci.com/account/api>                 |
| GITHUB_OAUTH_TOKEN              |         | Github personal access token: <https://github.com/settings/tokens> |
| MYSQL_PRODUCTION_ROOT_USER      |         | Production environment CloudSQL user with all privileges           |
| MYSQL_PRODUCTION_ROOT_PASSWORD  |         | Production environment CloudSQL password                           |
| MYSQL_DEVELOPMENT_ROOT_USER     |         | Development environment CloudSQL user with all privileges          |
| MYSQL_DEVELOPMENT_ROOT_PASSWORD |         | Develop environment CloudSQL password                              |

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

The NRO to be deleted is based upon how you have configured the ./configure.sh script. If you want to delete and existing NRO configure this script with the appropriate variables (using ./configure.sh) and then run the `make run delete-yes-i-mean-it` command.

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

## Updating common CircleCI configuration on all NROs

Use [this script](https://github.com/greenpeace/planet4-nro-generator/tree/master/bin/update_configs.sh) for centrally managing the CircleCI configuration file on all NROs.
Each NRO has a `.circleci/artifacts.yml` file which contains the NRO specific parts of the config. Currently, this file
needs to be created manually, and it needs to match what is in `.circleci/config.yml`. You are currently able to make
changes to `.circleci/config.yml`, however these changes would be overwritten by what is in `.circleci/artifacts.yml`.
In order to prevent that a script first runs that checks whether something would be overwritten. If the script detects
any out of sync files then you need to make the files match for those NROs (by applying the changes made in `config.yml`
to `artifacts.yml`).

Obviously this is not an ideal workflow, and we will change this later so that it's all in one place.

Apply the new configuration to <https://github.com/greenpeace/planet4-nro-generator/blob/master/templates/nro/.circleci/config.yml.tmpl>
and first perform a dry run (first parameter `false`).

```bash
bin/update_configs.sh false
```

This will check out the repositories and perform the change, but
not commit and push them. You can then inspect whether your changes looks ok and run it on dev sites.

```bash
bin/update_configs.sh true true
```

If dev sites look ok then you can first push the changes to one of the "test production" instances (comment out the line including the
actual production instances) and check if the dev and staging pipelines run well.

```bash
bin/update_configs.sh true true false
```

If that's ok you can push the changes
to production sites (third parameter `true`).
