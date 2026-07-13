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
    - **Gitea**
        - 2222/tcp (SSH)
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
- `./prometheus/.env`
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

The Caddy bouncer protects HTTP services. Stalwart's mail ports (25/465/587/143/993/110/995/4190) bypass Caddy, so install a firewall bouncer on the host. CrowdSec packages live on PackageCloud, not in the default apt repos, so add the repo first:

```sh
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | sudo bash
sudo apt install crowdsec-firewall-bouncer-nftables
```

Do NOT use `install.crowdsec.net` (that installs the engine too, which we already run in Docker).

Patch the default config (the package writes `api_url: http://127.0.0.1:8080/` but our LAPI is on 18080):

```sh
FW_KEY=$(grep '^CROWDSEC_BOUNCER_KEY_FW=' ./crowdsec/.env | cut -d= -f2)
sudo sed -i "s|^api_url:.*|api_url: http://127.0.0.1:18080/|" /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
sudo sed -i "s|^api_key:.*|api_key: $FW_KEY|" /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
sudo systemctl enable --now crowdsec-firewall-bouncer
sudo systemctl status crowdsec-firewall-bouncer --no-pager
```

Verify:

```sh
docker exec crowdsec cscli bouncers list      # 'firewall' should appear with a non-empty IP and recent 'Last API pull'
sudo nft list ruleset | grep crowdsec         # kernel-level rules in place
```

## Backups (optional, restic)

This is **optional** — use it only if you want off-site, encrypted backups of your service data. Here it is done with [restic](https://github.com/restic/restic) over SFTP (e.g. a Hetzner Storage Box). restic encrypts client-side, deduplicates and compresses, so no separate `tar`/`gzip` is needed. Run as **root**, since Docker-created service data is mostly root-owned.

Replace the placeholders: `USER@HOST:PORT` (SFTP target), `/path/to/restic-repo` (repo path on the server), `YOUR_PASSWORD` (losing it means the backup is unrecoverable), `/path/to/services` (directory to back up). Do not commit real secrets to git.

```sh
# 1. Install restic and set up passwordless SSH to the target (as root)
sudo apt install restic
sudo -i
ssh-keygen -t ed25519 && ssh-copy-id -p PORT USER@HOST   # no passphrase

# 2. Backup script: /usr/local/bin/restic-backup.sh  (chmod 700)
#!/bin/bash
export RESTIC_REPOSITORY="sftp://USER@HOST:PORT//path/to/restic-repo"   # note the double slash before an absolute path
export RESTIC_PASSWORD="YOUR_PASSWORD"
restic backup /path/to/services --compression max
restic forget --keep-last 3 --prune                       # keep only the 3 newest snapshots

# 3. Initialize once, then test
restic init
/usr/local/bin/restic-backup.sh && restic snapshots

# 4. Schedule via cron (3x/day at 06:00, 14:00, 22:00)
sudo crontab -e
# 0 6,14,22 * * * /usr/local/bin/restic-backup.sh >> /var/log/restic-backup.log 2>&1
```

Restore (from any machine with restic + repo access + password, as root):

```sh
restic snapshots
restic restore latest --target /restore/destination
```

Other useful commands: `restic check` (verify integrity), `restic unlock` (clear a stale lock), `restic stats`.

## Stopping Services

To stop all running services, use:

```sh
./main.sh stop
```
