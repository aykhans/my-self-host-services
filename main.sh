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
    cp --update=none ./blinko/.env.example ./blinko/.env
    cp --update=none ./caddy/Caddyfile.private.example ./caddy/Caddyfile.private
    # cp --update=none ./slash/.env.example ./slash/.env
    print_success ".env files generated."
}

start_services() {
    docker network create caddy 2>/dev/null

    echo "Starting gitea..."
    $DOCKER_COMPOSE_COMMAND -f ./gitea/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Gitea started successfully."
    else
        print_error "failed to start Gitea!"
        exit 1
    fi

    echo "Starting blinko..."
    $DOCKER_COMPOSE_COMMAND -f ./blinko/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Blinko started successfully."
    else
        print_error "failed to start Blinko!"
        exit 1
    fi

    echo "Starting sftpgo..."
    $DOCKER_COMPOSE_COMMAND -f ./sftpgo/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Sftpgo started successfully."
    else
        print_error "failed to start Sftpgo!"
        exit 1
    fi

    echo "Starting slash..."
    $DOCKER_COMPOSE_COMMAND -f ./slash/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Slash started successfully."
    else
        print_error "failed to start Slash!"
        exit 1
    fi

    echo "Starting vaultwarden..."
    $DOCKER_COMPOSE_COMMAND -f ./vaultwarden/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Vaultwarden started successfully."
    else
        print_error "failed to start Vaultwarden!"
        exit 1
    fi

    echo "Starting wg-easy..."
    $DOCKER_COMPOSE_COMMAND -f ./wg_easy/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Wg-easy started successfully."
    else
        print_error "failed to start Wg-easy!"
        exit 1
    fi

    echo "Starting glance..."
    $DOCKER_COMPOSE_COMMAND -f ./glance/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Glance started successfully."
    else
        print_error "failed to start Glance!"
        exit 1
    fi

    echo "Starting caddy..."
    $DOCKER_COMPOSE_COMMAND -f ./caddy/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Caddy started successfully."
    else
        print_error "failed to start Caddy!"
        exit 1
    fi
}

stop_services() {
    echo "Stopping gitea..."
    $DOCKER_COMPOSE_COMMAND -f ./gitea/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Gitea stopped successfully."
    else
        print_error "failed to stop Gitea!"
        exit 1
    fi

    echo "Stopping blinko..."
    $DOCKER_COMPOSE_COMMAND -f ./blinko/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Blinko stopped successfully."
    else
        print_error "failed to stop Blinko!"
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

    echo "Stopping caddy..."
    $DOCKER_COMPOSE_COMMAND -f ./caddy/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Caddy stopped successfully."
    else
        print_error "failed to stop Caddy!"
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
