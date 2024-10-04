#!/bin/bash

# Default variables
TPL_DIR_PATH="./tpl"
NAMESPACE="local"
DEST="infra"
DEFAULT_PASS="pass"
DEFAULT_USER="root"

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

    DEPENDENCIES=$deps
    configure
}

configure() {
    log "=+=================================================================+="
    log "\033[1;32mConfiguring dependencies for namespace:\033[0m $NAMESPACE"
    log "\033[1;32mDestination folder:\033[0m $DEST"
    log "\033[1;32mDesired images:\033[0m $DEPENDENCIES\n\n"

    install_helm_repo

    mkdir -p "$DEST/k8s" "$DEST/images"

    create_k8s_namespace
    create_k8s_service_account
    create_k8s_secrets
    create_skaffold_manifest

    echo '  - path: k8s/skaffold.yaml' >> "$DEST/skaffold.yaml"

    if [ -z "$DEPENDENCIES" ]; then
        log "No dependencies selected. Skipping configuration..."
    else
        for dep in $DEPENDENCIES; do
            cp -r "$TPL_DIR_PATH/img/$dep" "$DEST/images"
            echo "  - path: images/$dep/skaffold.yaml" >> "$DEST/skaffold.yaml"
            log "\033[1;32m - configured $dep\033[0m"
        done
    fi

    find "$DEST" -type f -name "*.yaml" -exec sed -i "" -r \
      -e "s/{{NAMESPACE}}/$NAMESPACE/g" \
      -e "s/{{DEFAULT_USER}}/$DEFAULT_USER/g" \
      -e "s/{{DEST}}/$DEST/g" {} \;
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

create_k8s_namespace() {
    kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml > "$DEST/k8s/namespace.yaml"
    log "\033[1;32m - k8s namespace created\033[0m"
}

create_k8s_service_account() {
    kubectl create serviceaccount "$DEST-service-account" --namespace "$NAMESPACE" --dry-run=client -o yaml > "$DEST/k8s/service-account.yaml"
    kubectl create clusterrole "$DEST-role" --verb=get,create,update,delete,list,patch,watch --resource=pods,pods/log,services,secrets,namespaces,secrets --dry-run=client -o yaml > "$DEST/k8s/cluster-role.yaml"
    kubectl create clusterrolebinding "$DEST-role-binding" --clusterrole="$DEST-role" --serviceaccount="$NAMESPACE:$DEST-service-account" --dry-run=client -o yaml > "$DEST/k8s/cluster-role-binding.yaml"
    log "\033[1;32m - k8s service account, role, and binding created\033[0m"
}

create_k8s_secrets() {
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
}

create_skaffold_manifest() {
    cp "$TPL_DIR_PATH/skaffold/k8s_manifest.tpl.yaml" "$DEST/k8s/skaffold.yaml"
    cp "$TPL_DIR_PATH/skaffold/skaffold_manifest.tpl.yaml" "$DEST/skaffold.yaml"
    log "\033[1;32m - skaffold manifest created\033[0m"
}

# Execute install by default
install