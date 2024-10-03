ARCH:=$(shell uname -m)


.PHONY: help # http://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
help: ##
	@grep -E '^[a-zA-Z0-9_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.DEFAULT_GOAL := help

.PHONY: build
build: ## Build local dev environment with desired preconfigured images and structure
	sh ./build.sh

.PHONY: install
install:  ## Install environment (brew, docker, minikube, kubectl, skaffold, helm, lens, git)
	sh ./install.sh