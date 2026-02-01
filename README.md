## Prerequisites
- **Bash**
- **Docker**
- **Docker compose**
- **Ports:**
  - **Caddy**
    - 80/tcp (HTTP)
    - 443/tcp (HTTPS)
  - **Stalwart**
    - 25/tcp (SMTP)
    - 110/tcp (POP3)
    - 995/tcp (POP3S)
    - 143/tcp (IMAP)
    - 993/tcp (IMAPS)
    - 465/tcp (SMTPS)
    - 587/tcp (SUBMISSION)
  - **Croc**
    - 9009/tcp (PICHAT)
    - 9010/tcp (SDR)
    - 9011/tcp (D-STAR)
  - **SFTPGo**
    - 2022/tcp (SFTP)
  - **WireGuard Easy**
    - 51820/udp (WireGuard)

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
- `./sftpgo/.env`
- `./vaultwarden/.env`
- `./glance/.env`
- `./ghost/.env`
- `./immich/.env`
- `./uptime_kuma/.env`
- `./croc/.env`
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
