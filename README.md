[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/new/template/espocrm-1?utm_medium=integration&utm_source=button&utm_campaign=espocrm)

# Deploy and Host EspoCRM on Railway

EspoCRM is an open-source CRM (AGPL-3.0) for managing accounts, contacts, leads, opportunities, cases, emails, calendars and workflows. It has a fast single-page web interface, a REST API, roles and team permissions, and an Entity Manager for adding your own fields, entities and layouts without code.

## About Hosting EspoCRM

Running EspoCRM properly takes more than the web app. Upstream's Docker setup has four parts: the PHP web app, a job daemon that runs scheduled jobs (email fetching, reminders, notifications, mass email), a WebSocket server for live updates, and a MySQL or MariaDB database. The three EspoCRM processes must share the same `data/`, `custom/` and `client/custom/` folders. This template runs them together in one EspoCRM service on a single Railway volume, puts MySQL in its own service with its own volume, generates the database and admin passwords, sets the site URL from the Railway domain, and proxies the WebSocket server through the public HTTPS domain.

## Common Use Cases

* Sales pipeline and lead management for a small or mid-sized team
* Customer support with cases, a knowledge base and inbound email
* A self-hosted, customisable alternative to Salesforce, HubSpot or Zoho CRM

## Dependencies for EspoCRM Hosting

* EspoCRM 10.1.3 (official `espocrm/espocrm` Apache image, pinned by digest), running the web app, job daemon and WebSocket server
* MySQL (Railway's MySQL service) on its own volume

### Deployment Dependencies

* EspoCRM Docker image: https://hub.docker.com/r/espocrm/espocrm
* EspoCRM Docker installation docs: https://docs.espocrm.com/administration/docker/installation/
* EspoCRM releases: https://github.com/espocrm/espocrm/releases
* Template source: https://github.com/aalfath/espocrm-railway-template

### Implementation Details

**Services**

| Service | What it does | Volume |
|---|---|---|
| EspoCRM | Apache + PHP web app on `PORT` (8080), the job daemon (`daemon.php`) and the WebSocket server (`websocket.php`, proxied on `/wss`) | `/espocrm-storage` (holds `data/`, `custom/`, `client/custom/`) |
| MySQL | Database, reached over the private network | `/var/lib/mysql` |

**After deploy**

1. Wait for the EspoCRM service to turn healthy (the first boot installs the database, about 1 to 2 minutes).
2. Open the EspoCRM service's Variables tab and copy `ESPOCRM_ADMIN_PASSWORD` (generated for you).
3. Log in at your Railway domain as `admin` with that password, then change the password under your profile.
4. Optional: set up outbound email under Administration > Outbound Emails, and inbound email accounts if you want email-to-case or email fetching. The job daemon is already running, so scheduled jobs need no cron setup.

**Variables**

| Variable | Default | Notes |
|---|---|---|
| `ESPOCRM_ADMIN_USERNAME` | `admin` | Username of the first admin, used on first boot only |
| `ESPOCRM_ADMIN_PASSWORD` | generated | Password of the first admin, used on first boot only. Change it in EspoCRM afterwards |
| `ESPOCRM_SITE_URL` | `https://${{RAILWAY_PUBLIC_DOMAIN}}` | Set to `https://YOUR-DOMAIN` when you add a custom domain; links and WebSockets follow it on the next deploy |
| `ESPOCRM_DATABASE_*` | references to the MySQL service | Leave as they are |
| `PORT` | `8080` | Port Apache listens on |

Any EspoCRM config setting can be set with an `ESPOCRM_CONFIG_*` variable, as in the official image (for example `ESPOCRM_CONFIG_TIME_ZONE=Europe/Berlin`).

**Updates**

The EspoCRM service builds from this repository. When a new EspoCRM version is pinned here, Railway shows "update available" on your project and you choose when to apply it. On the next start the official entrypoint runs EspoCRM's migrations. Read `CHANGELOG.md` before you update, and back up the MySQL volume first.

## Why Deploy EspoCRM on Railway?

<!-- Recommended: Keep this section as shown below -->
Railway is a singular platform to deploy your infrastructure stack. Railway will host your infrastructure so you don't have to deal with configuration, while allowing you to vertically and horizontally scale it.

By deploying EspoCRM on Railway, you are one step closer to supporting a complete full-stack application with minimal burden. Host your servers, databases, AI agents, and more on Railway.
<!-- End recommended section -->
