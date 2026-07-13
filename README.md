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

The Caddy bouncer protects HTTP services. Stalwart's mail ports (25/465/587/143/993/110/995/4190) bypass Caddy, so run a CrowdSec **firewall bouncer** on the host itself (nftables backend).

Configure it to talk to the engine's LAPI on `127.0.0.1:18080` (published by the crowdsec container) and give it an `api_key` equal to `CROWDSEC_BOUNCER_KEY_FW` from step 4. Do NOT install the CrowdSec engine on the host, it already runs in Docker. For installing and configuring the bouncer itself, see the official docs: https://docs.crowdsec.net/u/bouncers/firewall/ (repo: https://github.com/crowdsecurity/cs-firewall-bouncer).

Verify:

```sh
docker exec crowdsec cscli bouncers list      # 'firewall' should appear with a non-empty IP and recent 'Last API pull'
sudo nft list ruleset | grep crowdsec         # kernel-level rules in place
```

## Backups (optional, restic)

This is **optional**, use it only if you want off-site, encrypted backups of your service data. Here it is done with [restic](https://github.com/restic/restic) over SFTP (e.g. a Hetzner Storage Box). restic encrypts client-side, deduplicates and compresses, so no separate `tar`/`gzip` is needed. Run as **root**, since Docker-created service data is mostly root-owned.

Installing restic and scheduling the backup depend on the host and are out of scope here. Replace the placeholders: `USER@HOST:PORT` (SFTP target), `/path/to/restic-repo` (repo path on the server), `YOUR_PASSWORD` (losing it means the backup is unrecoverable), `/path/to/services` (directory to back up). Do not commit real secrets to git.

```sh
export RESTIC_REPOSITORY="sftp://USER@HOST:PORT//path/to/restic-repo"   # note the double slash before an absolute path
export RESTIC_PASSWORD="YOUR_PASSWORD"

restic init                                    # once
restic backup /path/to/services --compression max
restic forget --keep-last 3 --prune            # keep only the 3 newest snapshots
restic snapshots
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
