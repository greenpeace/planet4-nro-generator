FROM gcr.io/planet-4-151612/ubuntu:latest

RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-$(lsb_release -c -s) main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    apt-get update && \
    apt-get install -y -q --no-install-recommends \
      git-core \
      google-cloud-sdk \
      jq \
      make \
      mysql-client \
      rsync \
      unzip \
      && \
    rm -r /var/lib/apt/lists/*

RUN wget https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 -O /app/bin/cloud_sql_proxy && \
    chmod 755 /app/bin/cloud_sql_proxy && \
    ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts

WORKDIR /app

VOLUME /app/secrets

COPY . /app

CMD ["make","all"]

ENV \
    APP_HOSTNAME="greenpeace.org" \
    APP_HOSTPATH="" \
    GITHUB_REPOSITORY_NAME="planet4-base-test" \
    CIRCLE_PROJECT_USERNAME="greenpeace" \
    CIRCLE_TOKEN="" \
    CONTAINER_PREFIX="planet4-base-test" \
    GCP_DEVELOPMENT_CLOUDSQL="p4-develop-k8s" \
    GCP_DEVELOPMENT_CLUSTER="planet-4-151612" \
    GCP_DEVELOPMENT_PROJECT="planet-4-151612" \
    GCP_DEVELOPMENT_REGION="us-central1" \
    GCP_PRODUCTION_CLOUDSQL="planet4-prod" \
    GCP_PRODUCTION_CLUSTER="planet4-production" \
    GCP_PRODUCTION_PROJECT="planet4-production" \
    GCP_PRODUCTION_REGION="us-central1" \
    GITHUB_OAUTH_TOKEN="" \
    GITHUB_MACHINE_USER="greenpeace-circleci" \
    GOOGLE_PROJECT_ID="planet-4-151612" \
    INFRA_VERSION="latest" \
    MAKE_DEVELOP="true" \
    MAKE_MASTER="true" \
    MAKE_RELEASE="true" \
    MYSQL_DATABASE="wordpress" \
    MYSQL_DEVELOPMENT_ROOT_PASSWORD="" \
    MYSQL_DEVELOPMENT_ROOT_USER="root" \
    MYSQL_PASSWORD="" \
    MYSQL_PRODUCTION_ROOT_PASSWORD="" \
    MYSQL_PRODUCTION_ROOT_USER="root" \
    MYSQL_USERNAME="" \
    NEWRELIC_APPNAME="P4 Change My Name" \
    SOURCE_CONTENT_BUCKET="planet4-default-content" \
    SOURCE_CONTENT_SQLDUMP="planet4-defaultcontent_wordpress-v0.1.13.sql" \
    STATELESS_BUCKET_LOCATION="us" \
    WP_TITLE="Greenpeace" \
