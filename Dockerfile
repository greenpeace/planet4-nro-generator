# hadolint ignore=DL3007
FROM gcr.io/planet-4-151612/ubuntu:latest

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008
RUN echo "deb https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
  curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
  apt-get update && \
  apt-get install -y -q --no-install-recommends \
  git-core \
  google-cloud-cli \
  google-cloud-cli-gke-gcloud-auth-plugin \
  jq \
  make \
  mysql-client \
  python-setuptools \
  python3-pip \
  rsync \
  unzip \
  && \
  rm -fr /tmp/* /var/lib/apt/lists/* && \
  ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts && \
  curl -sSo /app/bin/cloud_sql_proxy https://dl.google.com/cloudsql/cloud_sql_proxy.linux.amd64 && \
  chmod 755 /app/bin/cloud_sql_proxy && \
  pip3 install --no-cache-dir yamllint==1.14.0

RUN curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
  && chmod +x ./kubectl \
  && mv ./kubectl /usr/local/bin/kubectl \
  && curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 \
  && chmod +x get_helm.sh && ./get_helm.sh

WORKDIR /app

VOLUME /app/secrets

COPY . /app

ENTRYPOINT ["/app/bin/entrypoint.sh"]

CMD ["make","all"]

ENV APP_HOSTNAME="greenpeace.org" \
  APP_HOSTPATH="" \
  BUILDER_VERSION="latest" \
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
  USE_GKE_GCLOUD_AUTH_PLUGIN="True" \
  GITHUB_MACHINE_USER="greenpeace-circleci" \
  GITHUB_OAUTH_TOKEN="" \
  GITHUB_REPOSITORY_NAME="planet4-base-test" \
  GOOGLE_PROJECT_ID="planet-4-151612" \
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
  SERVICE_ACCOUNT_NAME="" \
  SOURCE_CONTENT_BUCKET="planet4-default-content" \
  SOURCE_CONTENT_SQLDUMP="planet4-defaultcontent_wordpress-v0.2.54.sql" \
  STATELESS_BUCKET_LOCATION="us" \
  WP_TITLE="Greenpeace"