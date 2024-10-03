LOGFILE="$PWD/install_log.txt"
#KUBLO_ON_LINUX=0
#KUBLO_ON_MACOS=0


## First check OS.
#OS="$(uname)"
#if [[ "${OS}" == "Linux" ]]
#then
#  KUBLO_ON_LINUX=1
#elif [[ "${OS}" == "Darwin" ]]
#then
#  KUBLO_ON_MACOS=1
#else
#  abort "KUBLO is only supported on macOS and Linux."
#fi


# Logging function for better output
log() {
#    echo "$1" | tee -a "$LOGFILE"
    echo "$1"
}

# Function to handle errors
error_exit() {
    echo "$1" 1>&2
    echo "Check the log file for more details: $LOGFILE"
    exit 1
}

# Execute a command, log output and errors, and exit on error
execute() {
    echo "Executing: $1" >> "$LOGFILE"
    bash -c "$1" 2>>"$LOGFILE"
    if [ $? -ne 0 ]; then
        error_exit "Command failed: $1 "
    fi
}

logo() {
    printf "\033c\n\n"
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