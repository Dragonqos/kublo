#!/bin/bash

# Default variables
NAMESPACE="local"
DEST="infra"
DEFAULT_PASS="pass"
DEFAULT_USER="root"

DEPENDENCIES=(
  "redis;bitnami/redis;redis@26379:26379,redis-master@6379:6379"
  "mongodb;bitnami/mongodb;mongodb@27017:27017"
  "mariadb;bitnami/mariadb;mariadb@3306:3306"
  "elasticsearch;bitnami/elasticsearch;elasticsearch@9200:9200,elasticsearch-kibana@5601:5601"
  "rabbitmq;bitnami/rabbitmq;rabbitmq@5672:5672,rabbitmq@15672:15672"
  "kafka;bitnami/kafka,kafka-ui/kafka-ui;kafka-ui@80:9092"
  "cassandra;bitnami/cassandra;cassandra@9042:9042"
  "cockroachdb;cockroachdb/cockroachdb;cockroachdb@8080:26257"
  "postgresql;bitnami/postgresql;postgresql@5432:5432"
)

# Logging function for better output
log() {
#    echo "$1" | tee -a "$LOGFILE"
    echo "$1"
}

# Function to handle errors
error_exit() {
    echo "$1" 1>&2
    exit 1
}

# Execute a command, log output and errors, and exit on error
execute() {
    echo "Executing: $1"
    bash -c "$1"
    if [ $? -ne 0 ]; then
        error_exit "Command failed: $1 "
    fi
}

logo() {
    printf "\n\n"
    log "\033[1;34m888    d8P  888     888 888888b.   888      .d88888b.  \033[0m"
    log "\033[1;34m888   d8P   888     888 888   88b  888     d88P'  'Y88 \033[0m"
    log "\033[1;34m888  d8P    888     888 888   88P  888     888     888 \033[0m"
    log "\033[1;34m888d88K     888     888 8888888K.  888     888     888 \033[0m"
    log "\033[1;34m8888888b    888     888 888   Y88b 888     888     888 \033[0m"
    log "\033[1;34m888  Y88b   888     888 888    888 888     888     888 \033[0m"
    log "\033[1;34m888   Y88b  Y88b. .d88P 888   d88P 888     Y88b. .d88P \033[0m"
    log "\033[1;34m888    Y88b  'Y88888P'  8888888P'  88888888  Y88888P'  \033[0m"
    log "\n\n\033[1;32mKUBLO going to help you build simple Kubernetes (k8s + minikube) infrastructure for local development\033[0m"
    log "\033[1;32mwith some ready-to-go database and broker Docker images\033[0m\n\n"
}

install() {
    logo

    ## First check OS.
    OS="$(uname)"
    if [[ "${OS}" == "Linux" ]]
    then
      log "Running KUBLO on Linux..."
    elif [[ "${OS}" == "Darwin" ]]
    then
      log "Running KUBLO on macOS..."
    else
      abort "KUBLO is only supported on macOS and Linux."
    fi

    select_namespace
}

select_namespace() {
    read -p "Enter the k8s NAMESPACE to build: " namespace
    if [ "$namespace" != "" ]; then
      NAMESPACE=$namespace
    fi
    select_destination
}

select_destination() {
    read -p "Enter DESTINATION folder (also used as service prefix): " dest
    if [ "$dest" != "" ]; then
      DEST=$dest
    fi
    select_default_pass
}

select_default_pass() {
    read -p "Enter DEFAULT PASSWORD: " pass
    if [ "$pass" != "" ]; then
      DEFAULT_PASS=$pass
    fi
    select_dependencies
}

select_dependencies() {
    log "\033[1;32mPlease choose the dependencies to configure:\033[0m"
    log "0) None"
    log "1) Redis"
    log "2) Mongo"
    log "3) MariaDB"
    log "4) Elasticsearch"
    log "5) RabbitMQ"
    log "6) Kafka"
    log "7) Cassandra"
    log "8) Cockroachdb"
    log "9) Postgresql"
    log "10) All"
    read -p "Select (comma-separated list, e.g., 1,2,3): " selection

    deps=""
    log "$selection" | grep -q 1 && deps="$deps redis"
    log "$selection" | grep -q 2 && deps="$deps mongo"
    log "$selection" | grep -q 3 && deps="$deps mariadb"
    log "$selection" | grep -q 4 && deps="$deps elasticsearch"
    log "$selection" | grep -q 5 && deps="$deps rabbitmq"
    log "$selection" | grep -q 6 && deps="$deps kafka"
    log "$selection" | grep -q 7 && deps="$deps cassandra"
    log "$selection" | grep -q 8 && deps="$deps cockroachdb"
    log "$selection" | grep -q 9 && deps="$deps postgresql"
    log "$selection" | grep -q 10 && deps="redis mongo mariadb elasticsearch rabbitmq kafka cassandra cockroachdb postgresql"

    SELECTED_DEPENDENCIES=$deps
    configure
}

configure() {
    log "=+=================================================================+="
    log "\033[1;32mConfiguring dependencies for namespace:\033[0m $NAMESPACE"
    log "\033[1;32mDestination folder:\033[0m $DEST"
    log "\033[1;32mDesired images:\033[0m $SELECTED_DEPENDENCIES\n\n"

    mkdir -p "$DEST/k8s" "$DEST/images"

    install_helm_repo
    create_k8s_manifests
    create_skaffold_requirement_manifest

    if [ -z "$SELECTED_DEPENDENCIES" ]; then
        log "No dependencies selected. Skipping configuration..."
    else
        for dep in $SELECTED_DEPENDENCIES; do
          create_image_manifest "$dep"
        done
    fi

    log "Configuration complete."
}

install_helm_repo() {
  if brew list helm &>/dev/null; then
    log "Adding helm repo..."
    execute "helm repo add bitnami https://charts.bitnami.com/bitnami"
    execute "helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts"
    execute "helm repo add cockroachdb https://charts.cockroachdb.com/"
  fi
}

create_k8s_manifests() {
  kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml > "$DEST/k8s/namespace.yaml"

  kubectl create serviceaccount "$DEST-service-account" --namespace "$NAMESPACE" --dry-run=client -o yaml > "$DEST/k8s/service-account.yaml"
  kubectl create clusterrole "$DEST-role" --verb=get,create,update,delete,list,patch,watch --resource=pods,pods/log,services,secrets,namespaces,secrets --dry-run=client -o yaml > "$DEST/k8s/cluster-role.yaml"
  kubectl create clusterrolebinding "$DEST-role-binding" --clusterrole="$DEST-role" --serviceaccount="$NAMESPACE:$DEST-service-account" --dry-run=client -o yaml > "$DEST/k8s/cluster-role-binding.yaml"

  kubectl create secret generic "$DEST-secret" --type Opaque -n "$NAMESPACE" \
      --from-literal RABBITMQ_DSN="amqp://$DEFAULT_USER:$DEFAULT_PASS@rabbitmq.$NAMESPACE:5672" \
      --from-literal KAFKA_DSN="kafka-cluster.$NAMESPACE:9092" \
      --from-literal MONGO_DSN="mongodb://$DEFAULT_USER:$DEFAULT_PASS@mongodb.$NAMESPACE:27017" \
      --from-literal ELASTICSEARCH_DSN="http://elasticsearch.$NAMESPACE:9200" \
      --from-literal REDIS_DSN="redis.$NAMESPACE:6379" \
      --from-literal REDIS_SENTINEL_DSN="redis-sentinel.$NAMESPACE:26379" \
      --dry-run=client -o yaml > "$DEST/k8s/secrets.yaml"

  kubectl create secret generic secrets-pass --type Opaque -n "$NAMESPACE" \
      --from-literal=redis-password="$DEFAULT_PASS" \
      --from-literal=redis-sentinel-password="$DEFAULT_PASS" \
      --from-literal=mongodb-passwords="$DEFAULT_PASS" \
      --from-literal=mongodb-root-password="$DEFAULT_PASS" \
      --from-literal=mariadb-root-password="$DEFAULT_PASS" \
      --from-literal=mariadb-password="$DEFAULT_PASS" \
      --from-literal=elasticsearch-password="$DEFAULT_PASS" \
      --from-literal=rabbitmq-password="$DEFAULT_PASS" \
      --from-literal=kafka-password="$DEFAULT_PASS" \
      --from-literal=cassandra-password="$DEFAULT_PASS" \
      --from-literal=postgres-admin-password="$DEFAULT_PASS" \
      --from-literal=postgres-user-password="$DEFAULT_PASS" \
      --from-literal=postgres-replication-password="$DEFAULT_PASS" \
      --dry-run=client -o yaml > "$DEST/k8s/secrets.pass.yaml"

  cat <<YAML >> "$DEST/k8s/skaffold.yaml"
---
apiVersion: skaffold/v4beta11
kind: Config
profiles:
  - name: local
    activation:
      - kubeContext: minikube
    deploy:
      kubectl:
        defaultNamespace: $NAMESPACE
      kubeContext: minikube
    manifests:
      rawYaml:
        - namespace.yaml
        - service-account.yaml
        - cluster-role.yaml
        - cluster-role-binding.yaml
        - secrets.yaml
        - secrets.pass.yaml
YAML
}

create_skaffold_requirement_manifest() {
  rm -rf $DEST/skaffold.yaml
  cat <<YAML >> "$DEST/skaffold.yaml"
---
apiVersion: skaffold/v4beta11
kind: Config
metadata:
  name: $DEST
requires:
YAML

  echo '  - path: k8s/skaffold.yaml' >> "$DEST/skaffold.yaml"
}

create_image_manifest() {
  local dep=$1
  local output_file="$DEST/images/$dep/skaffold.yaml"

  mkdir -p "$DEST/images/$dep"
  rm -rf "$output_file"

  IFS=';' read -r _ releases ports <<< "$(get_dependency_config "$dep")"
  IFS=',' read -ra release_array <<< "$releases"
  IFS=',' read -ra port_array <<< "$ports"

  if [ ! -f "$output_file" ]; then
    cat <<YAML >> "$output_file"
---
apiVersion: skaffold/v4beta11
kind: Config
metadata:
  name: $NAMESPACE-$dep

build:
  artifacts: []

deploy:
  kubeContext: minikube
  helm:
    releases:
YAML
  fi

  for remote_chart in "${release_array[@]}"; do
    IFS='/' read -r _ resource_name <<< "$remote_chart"
    echo "      - name: $resource_name" >> "$output_file"
    echo "        remoteChart: $remote_chart" >> "$output_file"
    echo "        namespace: $NAMESPACE" >> "$output_file"
    echo "        valuesFiles: " >> "$output_file"
    echo "          - $resource_name.values.yaml" >> "$output_file"

    generate_helm_values "$dep" "$resource_name"
  done

  echo "portForward:" >> "$output_file"

  for port in "${port_array[@]}"; do
    IFS='@' read -r resource_name port_mapping <<< "$port"
    IFS=':' read -r image_port local_port <<< "$port_mapping"
    echo "  - resourceType: service" >> "$output_file"
    echo "    resourceName: $resource_name" >> "$output_file"
    echo "    namespace: $NAMESPACE" >> "$output_file"
    echo "    port: $image_port" >> "$output_file"
    echo "    localPort: $local_port" >> "$output_file"
  done

  echo "  - path: images/$dep/skaffold.yaml" >> "$DEST/skaffold.yaml"
}

generate_helm_values() {
  local dep=$1
  local resource=$2
  local values_file="$DEST/images/$dep/$resource.values.yaml"

  rm -rf "$values_file"
  mkdir -p "$(dirname "$values_file")"

  case $dep in
    redis)
      cat <<YAML > "$values_file"
## Full configuration lives here: https://github.com/bitnami/charts/blob/main/bitnami/redis/values.yaml
architecture: replication
auth:
  existingSecret: secrets-pass
  existingSecretPasswordKey: redis-password
  enabled: true
  sentinel: true
rbac:
  create: true
serviceAccount:
  create: true
  automountServiceAccountToken: true
master:
  automountServiceAccountToken: true
  persistence:
    enabled: true
    size: 1Gi
replica:
  automountServiceAccountToken: true
sentinel:
  enabled: true
  count: 2
  quorum: 2
  service:
    createMaster: true
  externalMaster:
    enabled: true
  resourcesPreset: nano
YAML
      ;;
    mongo)
      cat <<YAML > "$values_file"
##  Full configuration lives here: https://github.com/bitnami/charts/blob/main/bitnami/mongodb/values.yaml
architecture: standalone
useStatefulSet: true
# Bitnami do not support Apple silicon ARM64 for MongoDB images
# https://github.com/ZCube/bitnami-compat/pkgs/container/bitnami-compat%2Fmongodb - kindly prepared documentation but only have compiled MongoDB 6.0 version
# https://github.com/xavidop/mongodb-7-bitnami/pkgs/container/mongodb Fortunately we still can use bitnami HELM chart with xavidop image instead
# https://github.com/bitnami/charts/issues/3635
image:
  registry: ghcr.io
  repository: xavidop/mongodb
  tag: "7.0"
auth:
  enabled: true
  rootUser: $DEFAULT_USER
  existingSecret: "secrets-pass"
YAML
      ;;
    mariadb)
      cat <<YAML > "$values_file"
##  Full configuration lives here: https://github.com/bitnami/charts/blob/main/bitnami/mariadb/values.yaml
architecture: standalone
auth:
  enabled: true
  database: "app"
  existingSecret: "secrets-pass"
YAML
      ;;
    elasticsearch)
      cat <<YAML > "$values_file"
##  Full configuration lives here: https://github.com/bitnami/charts/blob/main/bitnami/elasticsearch/values.yaml
global:
  kibanaEnabled: true
security:
  enabled: false
kibana:
  elasticsearch:
    security:
      auth:
        enabled: false
master:
  masterOnly: false
  replicaCount: 1
data:
  replicaCount: 0
coordinating:
  replicaCount: 0
ingest:
  replicaCount: 0
YAML
      ;;
    rabbitmq)
      cat <<YAML > "$values_file"
## Full configuration lives here: https://github.com/bitnami/charts/blob/main/bitnami/rabbitmq/values.yaml
auth:
  username: $DEFAULT_USER
  existingPasswordSecret: "secrets-pass"
YAML
      ;;
    kafka-ui)
      cat <<YAML > "$values_file"
## Full configuration lives here: https://github.com/provectus/kafka-ui-charts/blob/main/charts/kafka-ui/values.yaml
replicaCount: 1
image:
  repository: provectuslabs/kafka-ui
yamlApplicationConfig:
  kafka:
    clusters:
      - name: kafka-cluster
        bootstrapServers: kafka-cluster:9092
  management:
    health:
      ldap:
        enabled: false
  auth:
    type: disabled
env:
  - { name: DYNAMIC_CONFIG_ENABLED, value: 'true' }
YAML
      ;;
    kafka)
      cat <<YAML > "$values_file"
## Full configuration lives here: https://github.com/bitnami/charts/blob/main/bitnami/rabbitmq/values.yaml
extraConfig:
  default.replication.factor: 1 # 1
  offsets.topic.replication.factor: 1 # 3
  transaction.state.log.replication.factor: 1 # 3
  transaction.state.log.min.isr: 1 # 2
controller:
  replicaCount: 1
  persistence:
    enabled: false
broker:
  replicaCount: 0
  persistence:
    enabled: false
kraft:
  enabled: true
zookeeper:
  enabled: false
  replicaCount: 0
  persistence:
    enabled: false
listeners:
  client:
    containerPort: 9092
    protocol: PLAINTEXT
    name: CLIENT
    sslClientAuth: ""
  controller:
    name: CONTROLLER
    containerPort: 9093
    protocol: PLAINTEXT
    sslClientAuth: ""
  interbroker:
    containerPort: 9094
    protocol: PLAINTEXT
    name: INTERNAL
    sslClientAuth: ""
  external:
    containerPort: 9095
    protocol: PLAINTEXT
    name: EXTERNAL
    sslClientAuth: ""
YAML
      ;;
    cassandra)
      cat <<YAML > "$values_file"
##  Full configuration lives here: https://github.com/bitnami/charts/blob/main/bitnami/cassandra/values.yaml
dbUser:
  user: $DEFAULT_USER
  existingSecret: "secrets-pass"
YAML
      ;;
    cockroachdb)
      cat <<YAML > "$values_file"
##  Full configuration lives here: https://github.com/cockroachdb/helm-charts/blob/master/cockroachdb/values.yaml
YAML
      ;;
    postgresql)
      cat <<YAML > "$values_file"
##  Full configuration lives here: https://github.com/bitnami/charts/blob/main/bitnami/postgresql/values.yaml
architecture: standalone
auth:
  username: $DEFAULT_USER
  database: app
  existingSecret: "secrets-pass"
  secretKeys:
    adminPasswordKey: postgres-admin-password
    userPasswordKey: postgres-user-password
    replicationPasswordKey: postgres-replication-password
YAML
      ;;
    *)
      echo "No predefined values for $dep."
      ;;
  esac
}

get_dependency_config() {
  local dep_name=$1
  for dependency_config in "${DEPENDENCIES[@]}"; do
    if [[ "$dependency_config" == "$dep_name"* ]]; then
      echo "$dependency_config"
      return
    fi
  done
}


# Execute install by default
install