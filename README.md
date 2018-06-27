# Planet 4 NRO Generator

## Requirements:

Service accounts for Cloud Storage and CloudSQL, values in `secrets/env` populated (see `secrets/env.example`), and a valid Github SSH deploy key at `~/.ssh/id_rsa`.

File structure as follows:

```
secrets/cloudsql-service-account.json
secrets/stateless-service-account.json
secrets/env
```

## Deploying a New Planet4 CI Pipeline

### Quickstart:
1.  Copy Cloud Storage and CloudSQL service account keys into `secrets`
1.  Configure the file `secrets/env`. I suggest naming your file `env.<path of nro>` for example `env.coolpath`, then symlinking to that file:
```
ln -s secrets/env.coolpath secrets/env
cp secrets/env.example secrets/env.coolpath
```
1.  Deploy with `make run`

### Configure:

  Variable| Default | Values
--|---|--
STATELESS_BUCKET_LOCATION  |  us |  https://cloud.google.com/storage/docs/bucket-locations#available_locations

### Deploy

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

Run the full command instead of `make run` if, for example, you wish to use a different SSH key by modifying the line `$(HOME)/.ssh/id_rsa`

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
