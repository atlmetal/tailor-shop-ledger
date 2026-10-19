# Deploy

Production runs with Kamal at `taller.yunquelabs.com`, on a VPS it shares with the owner's gym app: the app, PostgreSQL as an accessory of its own, and one kamal-proxy for HTTPS in front of both apps. These steps rebuild it from scratch.

## Server

An OVHcloud US VPS-1 (2 vCores, 4 GB of RAM) with Ubuntu 26.04 LTS, set up for the gym app. On a new server, add your SSH public key with the temporary password from OVH's email, if the order didn't take it:

```sh
ssh-copy-id -i ~/.ssh/id_ed25519.pub ubuntu@<ip>
```

Then set the server up from your machine:

```sh
ssh ubuntu@<ip> 'bash -s' <<'REMOTE'
set -euo pipefail
APT="sudo DEBIAN_FRONTEND=noninteractive apt-get -qq -y -o Dpkg::Options::=--force-confdef -o Dpkg::Options::=--force-confold"

# SSH: keys only, no root. 00- sorts before cloud-init's 50- file, and sshd keeps the first value it reads.
sudo tee /etc/ssh/sshd_config.d/00-hardening.conf >/dev/null <<'EOF'
# Keys only, and no root login: Kamal deploys as ubuntu.
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin no
EOF
sudo sshd -t
sudo systemctl reload ssh

# Firewall: SSH, HTTP and HTTPS in; everything out.
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow OpenSSH
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable

# Security updates install by themselves; the ones that need a reboot take effect at 09:00 UTC,
# 4 a.m. in Bogotá, after both apps' nightly backups.
sudo tee /etc/apt/apt.conf.d/52-automatic-reboot >/dev/null <<'EOF'
Unattended-Upgrade::Automatic-Reboot "true";
Unattended-Upgrade::Automatic-Reboot-Time "09:00";
EOF

# Everything up to date, the kernel included.
sudo apt-get -qq update
$APT full-upgrade

# Docker Engine from Docker's repository, usable by ubuntu without sudo. Kamal builds images on your machine.
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt-get -qq update
$APT install docker-ce docker-ce-cli containerd.io
sudo usermod -aG docker ubuntu

sudo systemctl reboot
REMOTE
```

Once it's back, a password login must be refused:

```sh
ssh -o PubkeyAuthentication=no ubuntu@<ip>   # Permission denied (publickey).
```

Docker publishes container ports past the firewall, so only kamal-proxy publishes any, 80 and 443; both apps' PostgreSQL stay on Docker's private network.

## DNS

In Cloudflare, under `yunquelabs.com`, an `A` record named `taller` pointing at the server, with the proxy off ("DNS only"), so kamal-proxy can get its Let's Encrypt certificate.

## Kamal

Kamal builds the image on your machine, which needs Docker with your user in the `docker` group, and pushes it to a registry it runs there on `localhost:5555`; the server pulls it through the SSH connection. `config/deploy.yml` names the server.

```sh
bin/kamal setup    # the first time: PostgreSQL and the app
bin/kamal deploy   # every time after
```

Kamal builds from a clone of the last commit, so commit a change before deploying it, `config/credentials.yml.enc` included. The app's entrypoint runs `bin/rails db:prepare`, which creates the four databases (primary, cache, queue and cable) on the first boot and migrates them on every deploy. `bin/kamal console`, `bin/kamal logs` and `bin/kamal dbc` reach production.

Both apps use the same kamal-proxy, at the same Kamal version, so they move to a new Kamal together. Deploys leave the running proxy alone; `bin/kamal proxy reboot` restarts it under both apps, taking them offline for a moment.

`.kamal/secrets` reads the secrets from the encrypted credentials with `bin/rails credentials:fetch`. Only `config/master.key` opens them, and it is in no repository: keep a copy in a password manager, or nobody can deploy again.

## Shops and passwords

Shops are created from your machine, inside the app container that is running. `shops:create` prints the user's password once; `STARTED_ON` is the first day the shop wrote down, today when it's left out:

```sh
bin/kamal app exec --reuse 'bin/rails shops:create NAME="Modistería La Puntada" USER_NAME="Ana Gómez" USER_EMAIL=ana@example.com STARTED_ON=2026-10-01'
```

A user who forgets their password gets a new one, printed once, and is signed out everywhere:

```sh
bin/kamal app exec --reuse 'bin/rails users:new_password EMAIL=ana@example.com'
```

## Backups

Every night at 3:30 a.m. Bogotá time, half an hour after the gym app's, `BackupJob` dumps the primary database with `pg_dump` and uploads it to Cloudflare R2. The cache, queue and cable databases aren't backed up: `db:prepare` rebuilds them empty. Then the job pings Healthchecks.io, which emails when a night's backup fails or doesn't run.

In the Cloudflare dashboard, R2 needs its subscription first, which costs nothing within the free tier but asks for a payment method on file. Then, under R2:

1. A bucket named `tailor-shop-ledger-backups`, with an automatic location and the Standard storage class.
2. In the bucket's settings, an object lifecycle rule that deletes objects 30 days after they're uploaded.
3. An Account API token with Object Read & Write on that bucket only. Cloudflare shows its keys once.

In Healthchecks.io, whose free plan is enough, a check named `tailor-shop-ledger backup` with a cron schedule of `30 3 * * *` in the `America/Bogota` time zone, and an hour of grace time. Its email integration goes to the account's address.

The bucket, the token's keys and the check's ping URL go into the encrypted credentials, with `bin/rails credentials:edit`:

```yaml
r2:
  account_id: <the account ID on R2's overview>
  bucket: tailor-shop-ledger-backups
  access_key_id: <the token's access key ID>
  secret_access_key: <the token's secret access key>
healthchecks:
  ping_url: <the check's ping URL, https://hc-ping.com/...>
```

To take a backup by hand, before a risky deploy for example, run `BackupJob.perform_now` in `bin/kamal console`. It pings the check too. Without an interactive terminal, the same in one command:

```sh
bin/kamal app exec --reuse 'bin/rails runner "BackupJob.perform_now"'
```

Anyone who has the check's ping URL can ping it and hide a failing backup, so it's a secret. If it leaks, create a new check with the same settings, put its URL in the credentials, deploy, take a backup by hand to see the new check's ping arrive, and then delete the old check.

## Restoring a backup

Each dump is a `pg_dump` archive named after the database and the time it was taken, in UTC, such as `tailor_shop_ledger_production-20261019T083000Z.dump`. To get one, open the `tailor-shop-ledger-backups` bucket under R2 in the Cloudflare dashboard and choose Download in the dump's menu: it needs neither the server nor `config/master.key`. The dump holds the users' names and email addresses and every shop's records, so delete the file once you're done.

### On your machine

Restoring a dump locally is the drill that shows the backups work.

1. Restore it into a new database, leaving out the production role and its grants, which your PostgreSQL doesn't have:

   ```sh
   createdb tailor_shop_ledger_restore
   pg_restore --no-owner --no-acl --dbname=tailor_shop_ledger_restore tailor_shop_ledger_production-<time>.dump
   ```

2. Run the app on it. Every migration must show `up`, but those your code has and the deployed one doesn't, which show `down`: migrate them as the next deploy will, sending the schema dump elsewhere so `db/schema.rb` stays as it is.

   ```sh
   DATABASE_URL=postgres:///tailor_shop_ledger_restore bin/rails db:migrate:status
   DATABASE_URL=postgres:///tailor_shop_ledger_restore SCHEMA=/tmp/restore_schema.rb bin/rails db:migrate
   DATABASE_URL=postgres:///tailor_shop_ledger_restore bin/dev
   ```

3. Drop the database when you're done, since it holds the same data: `dropdb tailor_shop_ledger_restore`.

### On the server

On a server rebuilt with the steps above, restore after `bin/kamal setup`. On the current one, everything written since the dump is lost: take a backup by hand first.

1. Stop the app, so nothing writes while the database is replaced:

   ```sh
   bin/kamal app stop
   ```

   It also takes the app off kamal-proxy, so until step 3 the site fails with a TLS error instead of an error page.

2. Restore the dump over the production database in one transaction, which leaves the database as it was if any step fails. pg_restore prints nothing when it succeeds:

   ```sh
   ssh ubuntu@<ip> docker exec -i tailor_shop_ledger-db pg_restore --clean --if-exists --single-transaction --no-owner --no-acl --username=tailor_shop_ledger --dbname=tailor_shop_ledger_production < tailor_shop_ledger_production-<time>.dump
   ```

3. Start the app again with `bin/kamal deploy`, not `bin/kamal app start`, which only finds the stopped container if your current commit is the one deployed. On boot, `db:prepare` migrates the restored database if the dump is older than the code.

## Errors and monitoring

Sentry receives production errors, in a project of this app's own. Sentry's free plan has a single uptime monitor and a single cron monitor, which the gym app uses: Healthchecks.io watches the nightly backup instead, and the gym app's uptime monitor covers the server. If only this app goes down, nothing warns.

1. A Sentry project for Rails, with error monitoring only, and "Prevent Storing of IP Addresses" turned on under its Security & Privacy settings.
2. The project's DSN goes into the encrypted credentials as `sentry.dsn`, and `.kamal/secrets` passes it to the app as `SENTRY_DSN`.

The project's default alert, "Send a notification for high priority issues", emails new errors, a failed backup among them. The SDK's defaults keep personal data out of the events, and `config/initializers/sentry.rb` also drops the row that PostgreSQL quotes in its errors.
