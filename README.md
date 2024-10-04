# KUBLO: Kubernetes Environment Setup Tool

`Kublo` is a tool designed to automate and simplify the process of setting up Kubernetes environments for local development using `Skaffold`, `Minikube`, and other dependencies. It helps generate Kubernetes manifests, Helm charts, and other configurations.

---

## Installation

You can install `Kublo` using the Docker image or run it directly with a Makefile.

### Option 1: Using Go binary

1. Install Go binary
   ```bash
   go env -w GO111MODULE=on && go install github.com/Dragonqos/kublo@latest
   kublo
   ```

### Option 2: Using Makefile

1. Clone the repository:
    ```bash
    git clone git@github.com:Dragonqos/kublo.git && cd kublo
    make build
    ```
---
   
## Usage

After installation, you can use `Kublo` to create Kubernetes configuration files, deploy services, and set up local infrastructure for development

```bash
kublo
```

You will be prompted to enter the following information:

- Namespace: The Kubernetes namespace for the environment.
- Destination Folder: The folder where the generated configuration files will be placed.
- Dependencies: Choose the dependencies you want to include (e.g., Kafka, Rabbit, Redis, Mongo, Elasticsearch, MariaDB etc...).

Once you complete these steps, `Kublo` will generate Kubernetes YAML manifests and a `skaffold.yaml` file based on your selection.

## Contributing

Contributions are welcome! Feel free to submit pull requests or open issues on GitHub.

1. Fork the repository.
2. Create a new branch for your feature.
3. Submit a pull request.

## License

Kublo is licensed under the MIT License.
