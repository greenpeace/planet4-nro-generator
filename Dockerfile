FROM gcr.io/planet-4-151612/ubuntu:latest

RUN apt-get update && \
    apt-get install -y -q --no-install-recommends \
     git-core \
     jq \
     make \
     rsync \
     && \
    apt-get clean && \
    rm -r /var/lib/apt/lists/* && \
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

WORKDIR /app

VOLUME /app/secrets

COPY . /app

ENTRYPOINT ["make"]

CMD ["all"]

ENV \
  APP_HOSTPATH="" \
  CIRCLE_PROJECT_REPONAME="planet4-base-test" \
  CIRCLE_PROJECT_USERNAME="greenpeace" \
  CIRCLE_TOKEN="" \
  CONTAINER_PREFIX="planet4-base-test" \
  GITHUB_OUTH_TOKEN="" \
  INFRA_VERSION="v0.7.2" \
  NEWRELIC_APPNAME="P4 Change My Name" \
  SQLPROXY_KEY="" \
  WP_STATELESS_KEY=""
