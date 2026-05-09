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
    - 4190/tcp (ManageSieve)
  - **Croc**
    - 9009-9013/tcp (relay)
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
- `./stalwart/.env`
- `./caddy/.env`
- `./crowdsec/.env`
- `./caddy/Caddyfile.private`

### 4. Bouncer Keys (CrowdSec)
Generate two keys and write them into the matching `.env` files:
```sh
CADDY_KEY=$(openssl rand -hex 32)
FW_KEY=$(openssl rand -hex 32)

# crowdsec/.env
sed -i "s|^CROWDSEC_BOUNCER_KEY_CADDY=.*|CROWDSEC_BOUNCER_KEY_CADDY=$CADDY_KEY|" ./crowdsec/.env
sed -i "s|^CROWDSEC_BOUNCER_KEY_FW=.*|CROWDSEC_BOUNCER_KEY_FW=$FW_KEY|" ./crowdsec/.env

# caddy/.env (same value as CADDY key above)
sed -i "s|^CROWDSEC_API_KEY=.*|CROWDSEC_API_KEY=$CADDY_KEY|" ./caddy/.env
```

(Optional) get a Console enroll key from https://app.crowdsec.net and put it in `CROWDSEC_ENROLL_KEY`.

### 5. Start Services
Launch all services with the following command:
```sh
./main.sh start
```

### 6. Host Firewall Bouncer (CrowdSec, nftables)
The Caddy bouncer protects HTTP services. Stalwart's mail ports (25/465/587/143/993/110/995/4190) bypass Caddy, so install a firewall bouncer on the host:
```sh
sudo apt install crowdsec-firewall-bouncer-nftables
```

Edit `/etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml`:
```yaml
mode: nftables
api_url: http://127.0.0.1:18080/
api_key: <value of CROWDSEC_BOUNCER_KEY_FW from crowdsec/.env>
update_frequency: 10s
```

Enable and start:
```sh
sudo systemctl enable --now crowdsec-firewall-bouncer
```

Verify:
```sh
docker exec crowdsec cscli bouncers list      # should show 'caddy' and 'firewall'
docker exec crowdsec cscli decisions list     # current bans
sudo nft list ruleset | grep -A2 crowdsec     # kernel-level rules in place
```

Allowlist your operator IP at any time:
```sh
docker exec crowdsec cscli allowlist create operator -d "Operator IPs"
docker exec crowdsec cscli allowlist add operator <your-public-ip>
```

## Stopping Services

To stop all running services, use:
```sh
./main.sh stop
```
