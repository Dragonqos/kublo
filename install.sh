#!/bin/bash

source ./utils.sh

logo

log "Starting installation... It may take a while. Meanwhile, you can grab a coffee."
# 1. Install Homebrew
if ! which brew &>/dev/null; then
    log "Installing Homebrew..."
    execute "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
else
    log "Homebrew already installed."
fi

# 2. Ensure git is installed
if ! brew list git &>/dev/null; then
    log "Installing git..."
    execute "brew install git"
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    read -p "Enter your github email: " email
    read -p "Enter your github password: " password
    execute "git config --global user.email $email"
    execute "git config --global user.password $password"
else
    log "git already installed."
fi

# 3. Ensure Docker is installed and logged in
if ! brew list --cask docker &>/dev/null; then
    log "Installing OrbStack..."
    execute "brew install orbstack"
#    execute "orb create ubuntu:jammy"
#    log "Installing Docker..."
#    execute "brew install --cask docker"
#    open -a Docker.app
#    log "Please complete the Docker setup and press [Enter] to continue."
#    log "Allocate the following resources in Docker Desktop:CPUs: 4 Memory: 8.5 GB"
#    read -p "Press [Enter] once Docker setup is complete..."
    log "Logging in to Docker HUB registry..."
    read -p "Enter your docker hub email: " email
    read -p "Enter your docker hub token: " token
    execute "docker login -u $email -p $token"
else
    log "OrbStack already installed."
fi

# 4. Install minikube
if ! brew list minikube &>/dev/null; then
    log "Installing minikube..."
    execute "brew install minikube"
    # Setup minikube
    log "Setting up minikube..."
    execute "minikube config set memory 8192"
    execute "minikube config set cpus 4"
else
    log "Minikube already installed."
fi

# 5. check if minikube running and if not start it
if ! minikube status | grep -q "host: Running"; then
    log "Starting minikube..."
    execute "minikube start"
else
    log "Minikube already running."
fi

# 6. Install skaffold
if ! brew list skaffold &>/dev/null; then
    log "Installing Skaffold"
    execute "brew install skaffold"
else
    log "Skaffold already installed."
fi

# 7. Install helm
if ! brew list helm &>/dev/null; then
    log "Installing Helm"
    execute "brew install helm"
    execute "helm repo add bitnami https://charts.bitnami.com/bitnami"
    execute "helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts"
else
    log "Helm already installed."
fi

# 8. Install openlens
if ! brew list openlens &>/dev/null; then
    log "Installing openlens..."
    execute "brew install --cask openlens"
else
    log "openlens already installed."
fi

# 9. Install Go
if ! brew list go &>/dev/null; then
    log "Installing Go..."
    execute "brew install go golangci-lint diffutils"
    export GOROOT=/opt/homebrew/opt/go/libexec
    export GOPATH=/opt/homebrew/opt/go
    export PATH=$PATH:$GOPATH/bin
    execute "go install go.uber.org/mock/mockgen@latest"
    execute "go install go.uber.org/mock/mockgen@latest"
else
    log "Go already installed."
fi

if [ ! -s "$LOGFILE" ]; then
    rm "$LOGFILE"
fi

# End of script confirmation
log "Installation complete. You can now run k8s cluster."