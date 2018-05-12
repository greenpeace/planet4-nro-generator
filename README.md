# Planet 4 NRO Generator

## Requirements:

Service accounts for Cloud Storage and CloudSQL, values in `secrets/env` populated (see `secrets/env.example`), and a valid Github SSH deploy key.

File structure as follows:

```
secrets/cloudsql-service-account.json
secrets/stateless-service-account.json
secrets/env
```

# Deploying a new NRO

```
# Simple:
make run

# Full command:
docker build -t p4-build .
docker run --rm -ti \
  -v "$(PWD)/secrets:/app/secrets" \
  -v "$(HOME)/.ssh/id_rsa:/root/.ssh/id_rsa" \
  p4-build
```

## Deleting all associated resources

Pass the Makefile target as a command parameter, eg:

```
docker run --rm -ti \
  -v "$(PWD)/secrets:/app/secrets" \
  -v "$(HOME)/.ssh/id_rsa:/root/.ssh/id_rsa" \
  p4-build delete-yes-i-mean-it

# or via Make
make run delete-yes-i-mean-it
```

Look in the Makefile for more commands you can pass to the container.
