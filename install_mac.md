# Quick note to setup all you need for local development with k8s

## Installation macOS

## 1. Homebrew and Git
```bash
# install homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

brew install git
# configure
git config --global user.name <User Name>
git config --global user.email <mail>@gmail.com

git config --global url."git@github.com:".insteadOf "https://github.com/"
```

## 2. Install and configure [Docker Desktop](https://www.docker.com/products/docker-desktop/):
```bash
brew install orbstack

## or if you prefer old good docker
brew install --cask docker
docker login -u <mail>@gmail.com -p <token>
```

    Allocate the following resources in Docker Desktop:  
    `CPUs: 4`  
    `Memory: 8.5 GB`  

## 3. Install and configure [Minikube](https://minikube.sigs.k8s.io/):

```bash
# Install
brew install kubectl
brew install minikube

# Configure
minikube config set cpus 4
minikube config set memory 8192

# Usage
minikube start
minikube stop
minikube delete
```

### 4. Install [Skaffold](https://skaffold.dev/):
```bash
brew install skaffold
```

### 5. Install [Helm](https://skaffold.dev/):
```bash
brew install helm
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add kafka-ui https://provectus.github.io/kafka-ui-charts
```

### 5. Install [Open Lens](https://flathub.org/apps/dev.k8slens.OpenLens):

```bash
brew install --cask openlens
```