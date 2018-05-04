#  Planet 4 NRO Generator

## Requirements:

- You will need to have access to the Google Cloud project "Planet4-production"
- A json key for a Service accounts with access to Cloud Storage 
- A json key for a Service account with access to CloudSQL
- A valid [Github SSH deploy key](https://help.github.com/articles/connecting-to-github-with-ssh/)
- A valid [circleCI personal token](https://circleci.com/account/api)
- Values in `secrets/env` populated (see `secrets/env.example`), 
- Docker installed and running in your computer

## secrets/env values explanations


- APP_HOSTPATH             -> the directory after the domain where the website will appear.
For example `/international/`

- CIRCLE_PROJECT_REPONAME  -> the circleCI AND github repo name that will be created
for example `planet4-netherlands`

- CIRCLE_TOKEN             -> A personal API token from CircleCI. 
You get it at : https://circleci.com/account/api

- CONTAINER_PREFIX         -> The prefix that will be added for each container that will be created. 
For example, if you give here the value: `planet4-netherands` , the script will create
the containers `planet4-netherands-develop` , `planet4-netherands-staging` , `planet4-netherands-production`

- GITHUB_OAUTH_TOKEN       -> personal github oauth token. 
Go to:  https://github.com/settings/tokens
and create a token with just the "repo" permissions.

- GITHUB_USER_EMAIL ->The email of your github account

- GITHUB_USER_NAME -> Your github username

## Instructions

1. Clone this repository localy to your computer
1. In the `secrets` directory, copy the env.example to env and edit the values as the above explanations
1. In the `secrets` directory, put the cloudSQL and cloud storage json keys, with the names so that you end up with the following structure 

```
secrets/cloudsql-service-account.json
secrets/stateless-service-account.json
secrets/env
```
1. Follow the instructions of "Deploying a new NRO"

# Deploying a new NRO
Assuming that your github key is named `id_rsa` and is located at `/.ssh/id_rsa`, then you need to run the following

```
docker run --rm -ti \
  -v "${PWD}/secrets:/app/secrets" \
  -v "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa" \
  gcr.io/planet-4-151612/p4-nro-generator
```
If your key has a different name or is located elsewhere, then edit the `${HOME}/.ssh/id_rsa` accordinly and run the command
