# KUBLO: Kubernetes Environment Setup Tool

`Kublo` is a tool designed to automate and simplify the process of setting up Kubernetes environments for local development using `Skaffold`, `Minikube`, and other dependencies. It helps generate Kubernetes manifests, Helm charts, and other configurations.

---

## Installation

You can install `Kublo` using the Docker image or run it directly with a Makefile.

### Option 1: Using shell script

   ```bash
   /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/Dragonqos/kublo/HEAD/build.sh)"
   ```



#### Option 2: Using Go binary

1. Install Go binary
   ```bash
   go env -w GO111MODULE=on && go install github.com/Dragonqos/kublo@latest
   ```
   
2. If that fails, make sure your GOPATH/bin is in your PATH. You can add it with:
   ```bash
   export PATH=$PATH:$(go env GOPATH)/bin
   ```

#### Option 3: Using Makefile

1. Clone the repository:
    ```bash
    git clone git@github.com:Dragonqos/kublo.git && cd kublo
    make build
    ```
---
   
## Running kublo

After installation, you can use `Kublo` to create Kubernetes configuration files, deploy services, and set up local infrastructure for development

Example
```bash
# just run and you are ready to go
kublo
```

```bash
888    d8P  888     888 888888b.   888      .d88888b.   ███████
888   d8P   888     888 888   88b  888     d88P'  'Y88  ███████
888  d8P    888     888 888   88P  888     888     888
888d88K     888     888 8888888K.  888     888     888
8888888b    888     888 888   Y88b 888     888     888
888  Y88b   888     888 888    888 888     888     888
888   Y88b  Y88b. .d88P 888   d88P 888     Y88b. .d88P
888    Y88b  'Y88888P'  8888888P'  88888888  Y88888P'


KUBLO going to help you build simple Kubernetes (k8s + minikube) infrastructure for local development
with some ready-to-go database and broker Docker images


Running KUBLO on macOS...
Enter the k8s NAMESPACE to build:
```

You will be prompted to enter the following information:

- Namespace: The Kubernetes namespace for the environment. Default namespace `local`
- Destination Folder: The folder where the generated configuration files will be placed. Default namespace `infra`
- Password: The default user is `root`  and default password is `pass`.
- Dependencies: Choose the dependencies you want to include (e.g., Kafka, Rabbit, Redis, Mongo, Elasticsearch, MariaDB etc...).

Once you complete these steps, `Kublo` will generate Kubernetes YAML manifests and a `skaffold.yaml` file based on your selection.
Then you only need to run Skaffold. Skaffold will run k8s and selected dependencies. 
   ```bash
   cd infra && skaffold dev
   ```

## Contributing

Contributions are welcome! Feel free to submit pull requests or open issues on GitHub.

1. Fork the repository.
2. Create a new branch for your feature.
3. Submit a pull request.

## License

Kublo is licensed under the MIT License.
