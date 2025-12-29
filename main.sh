#!/bin/bash

BLACK="\033[30m"
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
MAGENTA="\033[35m"
CYAN="\033[36m"
WHITE="\033[37m"
RESET="\033[0m"

colored() {
    echo -e "$1$2$RESET"
}

print_error() {
    echo "$(colored $RED "Error:") $1" >&2
}

print_success() {
    colored $GREEN "$1"
}

print_usage() {
    echo -e "Usage: $0 [command]\n"
    echo "Commands:"
    echo "  start: Start all services"
    echo "  stop: Stop all services"
    echo "  generate-env: Generate .env files for all services"
    echo "  help: Show this help message"
}

check_docker() {
    if ! command -v docker &>/dev/null; then
        print_error "Docker is not installed."
        exit 1
    fi
}

check_docker_compose() {
    check_docker

    local docker_compose_cmd=""
    if command -v docker compose &>/dev/null; then
        docker_compose_cmd="docker compose"
    elif command -v docker-compose &> /dev/null; then
        docker_compose_cmd="docker-compose"
    else
        print_error "Docker Compose is not installed."
        exit 1
    fi
    DOCKER_COMPOSE_COMMAND=$docker_compose_cmd
}

generate_env_files() {
    cp --update=none ./gitea/.env.example ./gitea/.env
    cp --update=none ./sftpgo/.env.example ./sftpgo/.env
    cp --update=none ./vaultwarden/.env.example ./vaultwarden/.env
    cp --update=none ./wg_easy/.env.example ./wg_easy/.env
    cp --update=none ./caddy/.env.example ./caddy/.env
    cp --update=none ./glance/.env.example ./glance/.env
    cp --update=none ./ghost/.env.example ./ghost/.env
    cp --update=none ./immich/.env.example ./immich/.env
    cp --update=none ./uptime_kuma/.env.example ./uptime_kuma/.env
    cp --update=none ./croc/.env.example ./croc/.env
    cp --update=none ./caddy/Caddyfile.private.example ./caddy/Caddyfile.private
    print_success ".env files generated."
}

start_services() {
    docker network create caddy 2>/dev/null
    docker network create grafana 2>/dev/null
    docker network create gitea 2>/dev/null

    echo "Starting prometheus..."
    $DOCKER_COMPOSE_COMMAND -f ./prometheus/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Prometheus started successfully."
    else
        print_error "failed to start Prometheus!"
        exit 1
    fi

    echo "Starting Grafana..."
    $DOCKER_COMPOSE_COMMAND -f ./grafana/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Grafana started successfully."
    else
        print_error "failed to start Grafana!"
        exit 1
    fi

    echo "Starting Gitea..."
    $DOCKER_COMPOSE_COMMAND -f ./gitea/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Gitea started successfully."
    else
        print_error "failed to start Gitea!"
        exit 1
    fi

    echo "Starting gitea..."
    $DOCKER_COMPOSE_COMMAND -f ./gitea/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Gitea started successfully."
    else
        print_error "failed to start Gitea!"
        exit 1
    fi

    echo "Starting memos..."
    $DOCKER_COMPOSE_COMMAND -f ./memos/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Memos started successfully."
    else
        print_error "failed to start Memos!"
        exit 1
    fi

    echo "Starting sftpgo..."
    $DOCKER_COMPOSE_COMMAND -f ./sftpgo/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Sftpgo started successfully."
    else
        print_error "failed to start Sftpgo!"
        exit 1
    fi

    echo "Starting slash..."
    $DOCKER_COMPOSE_COMMAND -f ./slash/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Slash started successfully."
    else
        print_error "failed to start Slash!"
        exit 1
    fi

    echo "Starting vaultwarden..."
    $DOCKER_COMPOSE_COMMAND -f ./vaultwarden/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Vaultwarden started successfully."
    else
        print_error "failed to start Vaultwarden!"
        exit 1
    fi

    echo "Starting wg-easy..."
    $DOCKER_COMPOSE_COMMAND -f ./wg_easy/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Wg-easy started successfully."
    else
        print_error "failed to start Wg-easy!"
        exit 1
    fi

    echo "Starting glance..."
    $DOCKER_COMPOSE_COMMAND -f ./glance/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Glance started successfully."
    else
        print_error "failed to start Glance!"
        exit 1
    fi

    echo "Starting ghost..."
    $DOCKER_COMPOSE_COMMAND -f ./ghost/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Ghost started successfully."
    else
        print_error "failed to start Ghost!"
        exit 1
    fi

    echo "Starting immich..."
    $DOCKER_COMPOSE_COMMAND -f ./immich/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Immich started successfully."
    else
        print_error "failed to start Immich!"
        exit 1
    fi

    echo "Starting uptime kuma..."
    $DOCKER_COMPOSE_COMMAND -f ./uptime_kuma/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Uptime kuma started successfully."
    else
        print_error "failed to start Uptime kuma!"
        exit 1
    fi

    echo "Starting croc..."
    $DOCKER_COMPOSE_COMMAND -f ./croc/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Croc started successfully."
    else
        print_error "failed to start Croc!"
        exit 1
    fi

    echo "Starting caddy..."
    $DOCKER_COMPOSE_COMMAND -f ./caddy/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Caddy started successfully."
    else
        print_error "failed to start Caddy!"
        exit 1
    fi

    echo "Starting watchtower..."
    $DOCKER_COMPOSE_COMMAND -f ./watchtower/docker-compose.yml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Watchtower started successfully."
    else
        print_error "failed to start Watchtower!"
        exit 1
    fi

    echo "Starting stalwart..."
    $DOCKER_COMPOSE_COMMAND -f ./stalwart/docker-compose.yaml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Stalwart started successfully."
    else
        print_error "failed to start Stalwart!"
        exit 1
    fi

    echo "Starting gopkg proxy..."
    $DOCKER_COMPOSE_COMMAND -f ./gopkg_proxy/docker-compose.yaml up --pull -d
    if [ $? -eq 0 ]; then
        print_success "Gopkg proxy started successfully."
    else
        print_error "failed to start Gopkg proxy!"
        exit 1
    fi
}

stop_services() {
    echo "Stopping grafana..."
    $DOCKER_COMPOSE_COMMAND -f ./grafana/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Grafana stopped successfully."
    else
        print_error "failed to stop Grafana!"
        exit 1
    fi

    echo "Stopping prometheus..."
    $DOCKER_COMPOSE_COMMAND -f ./prometheus/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Prometheus stopped successfully."
    else
        print_error "failed to stop Prometheus!"
        exit 1
    fi

    echo "Stopping gitea..."
    $DOCKER_COMPOSE_COMMAND -f ./gitea/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Gitea stopped successfully."
    else
        print_error "failed to stop Gitea!"
        exit 1
    fi

    echo "Stopping gitea..."
    $DOCKER_COMPOSE_COMMAND -f ./gitea/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Gitea stopped successfully."
    else
        print_error "failed to stop Gitea!"
        exit 1
    fi

    echo "Stopping memos..."
    $DOCKER_COMPOSE_COMMAND -f ./memos/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Memos stopped successfully."
    else
        print_error "failed to stop Memos!"
        exit 1
    fi

    echo "Stopping sftpgo..."
    $DOCKER_COMPOSE_COMMAND -f ./sftpgo/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Sftpgo stopped successfully."
    else
        print_error "failed to stop Sftpgo!"
        exit 1
    fi

    echo "Stopping slash..."
    $DOCKER_COMPOSE_COMMAND -f ./slash/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Slash stopped successfully."
    else
        print_error "failed to stop Slash!"
        exit 1
    fi

    echo "Stopping vaultwarden..."
    $DOCKER_COMPOSE_COMMAND -f ./vaultwarden/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Vaultwarden stopped successfully."
    else
        print_error "failed to stop Vaultwarden!"
        exit 1
    fi

    echo "Stopping wg-easy..."
    $DOCKER_COMPOSE_COMMAND -f ./wg_easy/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Wg-easy stopped successfully."
    else
        print_error "failed to stop Wg-easy!"
        exit 1
    fi

    echo "Stopping glance..."
    $DOCKER_COMPOSE_COMMAND -f ./glance/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Glance stopped successfully."
    else
        print_error "failed to stop Glance!"
        exit 1
    fi

    echo "Stopping ghost..."
    $DOCKER_COMPOSE_COMMAND -f ./ghost/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Ghost stopped successfully."
    else
        print_error "failed to stop Ghost!"
        exit 1
    fi

    echo "Stopping immich..."
    $DOCKER_COMPOSE_COMMAND -f ./immich/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Immich stopped successfully."
    else
        print_error "failed to stop Immich!"
        exit 1
    fi

    echo "Stopping uptime kuma..."
    $DOCKER_COMPOSE_COMMAND -f ./uptime_kuma/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Uptime kuma stopped successfully."
    else
        print_error "failed to stop Uptime kuma!"
        exit 1
    fi

    echo "Stopping croc..."
    $DOCKER_COMPOSE_COMMAND -f ./croc/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Croc stopped successfully."
    else
        print_error "failed to stop Croc!"
        exit 1
    fi

    echo "Stopping caddy..."
    $DOCKER_COMPOSE_COMMAND -f ./caddy/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Caddy stopped successfully."
    else
        print_error "failed to stop Caddy!"
        exit 1
    fi

    echo "Stopping watchtower..."
    $DOCKER_COMPOSE_COMMAND -f ./watchtower/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Watchtower stopped successfully."
    else
        print_error "failed to stop Watchtower!"
        exit 1
    fi

    echo "Stopping stalwart..."
    $DOCKER_COMPOSE_COMMAND -f ./stalwart/docker-compose.yaml down
    if [ $? -eq 0 ]; then
        print_success "Stalwart stopped successfully."
    else
        print_error "failed to stop Stalwart!"
        exit 1
    fi

    echo "Stopping gopkg proxy..."
    $DOCKER_COMPOSE_COMMAND -f ./gopkg_proxy/docker-compose.yaml down
    if [ $? -eq 0 ]; then
        print_success "Gopkg proxy stopped successfully."
    else
        print_error "failed to stop Gopkg proxy!"
        exit 1
    fi
}

if [ $# -lt 1 ]; then
    print_usage
    exit 1
fi

case $1 in
    start)
        check_docker_compose
        start_services
        ;;
    stop)
        check_docker_compose
        stop_services
        ;;
    generate-env)
        generate_env_files
        ;;
    help)
        print_usage
        ;;
    *)
        print_error "Invalid command: $1"
        print_usage
        exit 1
        ;;
esac
