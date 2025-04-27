## Prerequisites
- **Bash**
- **Docker**
- **Docker compose**

## Getting Started

Follow these steps to set up and start the services:
### 1. Grant Execute Permissions
Ensure the `main.sh` script has the necessary permissions:
```sh
chmod +x main.sh
```

### 2. Generate Environment Files
Create `.env` configuration files with the following command:
```sh
./main.sh generate-env
```

### 3. Configure Environment Variables
Edit the generated `.env` files to fill in the required fields:

- `./gitea/.env`
- `./searxng/.env`
- `./sftpgo/.env`
- `./vaultwarden/.env`
- `./wg_easy/.env`
- `./blinko/.env`
- `./ghost/.env`
- `./caddy/.env`
- `./caddy/Caddyfile.private`

### 4. Start Services
Launch all services with the following command:
```sh
./main.sh start
```
## Stopping Services

To stop all running services, use:
```sh
./main.sh stop
```
