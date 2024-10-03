#!/bin/bash

source ./utils.sh

# Default variables
NAMESPACE="local"
DEST="infra"
DEFAULT_PASS="pass"
DEFAULT_USER="root"

install() {
    logo
    select_namespace
}

select_namespace() {
    read -p "Enter the k8s NAMESPACE to build: " namespace
    NAMESPACE=$namespace
    select_destination
}

select_destination() {
    read -p "Enter DESTINATION folder (also used as service prefix): " dest
    DEST=$dest
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
    log "7) All"
    read -p "Select (comma-separated list, e.g., 1,2,3): " selection

    deps=""
    log "$selection" | grep -q 1 && deps="$deps redis"
    log "$selection" | grep -q 2 && deps="$deps mongo"
    log "$selection" | grep -q 3 && deps="$deps mariadb"
    log "$selection" | grep -q 4 && deps="$deps elasticsearch"
    log "$selection" | grep -q 5 && deps="$deps rabbitmq"
    log "$selection" | grep -q 6 && deps="$deps kafka"
    log "$selection" | grep -q 7 && deps="redis mongo mariadb elasticsearch rabbitmq kafka"

    DEPENDENCIES=$deps
    configure
}

configure() {
    log "=+=================================================================+="
    log "\033[1;32mConfiguring dependencies for namespace:\033[0m $NAMESPACE"
    log "\033[1;32mDestination folder:\033[0m $DEST"
    log "\033[1;32mDesired images:\033[0m $DEPENDENCIES\n\n"

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
            cp -r tpl/img/$dep "$DEST/images"
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
        --dry-run=client -o yaml > "$DEST/k8s/secrets.pass.yaml"
}

create_skaffold_manifest() {
    cp tpl/k8s_manifest.tpl.yaml "$DEST/k8s/skaffold.yaml"
    cp tpl/skaffold_manifest.tpl.yaml "$DEST/skaffold.yaml"
    log "\033[1;32m - skaffold manifest created\033[0m"
}

# Execute install by default
install