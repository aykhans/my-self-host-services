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

generate_env_files() {
    cp --update=none ./gitea/.env.example ./gitea/.env
    # cp --update=none ./memos/.env.example ./memos/.env
    cp --update=none ./searxng/.env.example ./searxng/.env
    cp --update=none ./sftpgo/.env.example ./sftpgo/.env
    # cp --update=none ./slash/.env.example ./slash/.env
    cp --update=none ./vaultwarden/.env.example ./vaultwarden/.env
    cp --update=none ./wg_easy/.env.example ./wg_easy/.env
    cp --update=none ./caddy/.env.example ./caddy/.env
    print_success ".env files generated."
}

start_services() {
    echo "Starting gitea..."
    docker compose -f ./gitea/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Gitea started successfully."
    else
        print_error "failed to start Gitea!"
        exit 1
    fi
    
    echo "Starting memos..."
    docker compose -f ./memos/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Memos started successfully."
    else
        print_error "failed to start Memos!"
        exit 1
    fi
    
    echo "Starting searxng..."
    docker compose -f ./searxng/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Searxng started successfully."
    else
        print_error "failed to start Searxng!"
        exit 1
    fi
    
    echo "Starting sftpgo..."
    docker compose -f ./sftpgo/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Sftpgo started successfully."
    else
        print_error "failed to start Sftpgo!"
        exit 1
    fi
    
    echo "Starting slash..."
    docker compose -f ./slash/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Slash started successfully."
    else
        print_error "failed to start Slash!"
        exit 1
    fi
    
    echo "Starting vaultwarden..."
    docker compose -f ./vaultwarden/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Vaultwarden started successfully."
    else
        print_error "failed to start Vaultwarden!"
        exit 1
    fi
    
    echo "Starting wg-easy..."
    docker compose -f ./wg_easy/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Wg-easy started successfully."
    else
        print_error "failed to start Wg-easy!"
        exit 1
    fi

    echo "Starting caddy..."
    docker compose -f ./caddy/docker-compose.yml up -d
    if [ $? -eq 0 ]; then
        print_success "Caddy started successfully."
    else
        print_error "failed to start Caddy!"
        exit 1
    fi
}

stop_services() {
    echo "Stopping gitea..."
    docker compose -f ./gitea/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Gitea stopped successfully."
    else
        print_error "failed to stop Gitea!"
        exit 1
    fi

    echo "Stopping memos..."
    docker compose -f ./memos/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Memos stopped successfully."
    else
        print_error "failed to stop Memos!"
        exit 1
    fi

    echo "Stopping searxng..."
    docker compose -f ./searxng/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Searxng stopped successfully."
    else
        print_error "failed to stop Searxng!"
        exit 1
    fi

    echo "Stopping sftpgo..."
    docker compose -f ./sftpgo/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Sftpgo stopped successfully."
    else
        print_error "failed to stop Sftpgo!"
        exit 1
    fi

    echo "Stopping slash..."
    docker compose -f ./slash/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Slash stopped successfully."
    else
        print_error "failed to stop Slash!"
        exit 1
    fi

    echo "Stopping vaultwarden..."
    docker compose -f ./vaultwarden/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Vaultwarden stopped successfully."
    else
        print_error "failed to stop Vaultwarden!"
        exit 1
    fi

    echo "Stopping wg-easy..."
    docker compose -f ./wg_easy/docker-compose.yml down
    if [ $? -eq 0 ]; then
        print_success "Wg-easy stopped successfully."
    else
        print_error "failed to stop Wg-easy!"
        exit 1
    fi

    echo "Stopping caddy..."
    docker compose -f ./caddy/docker-compose.yml down
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
        start_services
        ;;
    stop)
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
