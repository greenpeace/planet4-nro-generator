#  Planet 4 NRO Generator

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
docker run --rm -ti \
  -v "${PWD}/secrets:/app/secrets" \
  -v "${HOME}/.ssh/id_rsa:/root/.ssh/id_rsa" \
  gcr.io/planet-4-151612/p4-nro-generator
```
