# docker-nginx-certbot-proxy
A simple, automated way to launch an nginx TLS termination proxy employing Let's Encrypt certificates through Docker.

Other projects exist that do similar things:

* [JrCs/docker-letsencrypt-nginx-proxy-companion](https://github.com/JrCs/docker-letsencrypt-nginx-proxy-companion)
* [evertramos/docker-compose-letsencrypt-nginx-proxy-companion](https://github.com/evertramos/docker-compose-letsencrypt-nginx-proxy-companion)

Those projects aim for a more complicated use-case. They handle dynamically updating the nginx config as containers are
added to and removed from the system. This makes their configuration a bit more complicated -- even more complicated if
you don't want to have the Docker socket mounted in a container exposed to the internet.

This is directed at simpler, more static configurations. It proxies for exactly one domain name. The code is very
minimalistic, and everything runs in a single Debian-based container.

# How it Works
When the container launches, it uses `supervisord` (configured via `supervisord.conf`) to launch two processes, both
simple bash scripts.

The `run-nginx` script uses `envsubst` to replace the `SERVER_NAME` enviroment variable referenced in some nginx
configuration files with its actual value, and then launches nginx itself. When nginx initially launches there is only a
simple http server running. This simple http server serves static files from `/var/www/html` for requests to
`/.well-known/acme-challenge/`. Files at this path will be requested by LetsEncrypt to ensure that we actually own the
domain name for which we are requesting a certificate. All paths other than `/.well-known/acme-challenge` are
permanently redirected to `https`.

The `run-certbot` script attempts to get an initial certificate if we do not already have one at
`/etc/letsencrypt/live/${SERVER_NAME}/privkey.pem`. As part of getting a certificate, `certbot` will likely place files
at `/var/www/html/.well-known/acme-challenge` which LetsEncrypt will then read to verify domain ownership. Once we have
a certificate it will enable the `https` nginx server configuration. After that it will attempt to renew the certificate
once per day. When the certificate is actually renewed the nginx configuration will be reloaded without downtime.

# Configuration
The container expects two environment variables to be set:

Environment Variable | Description
-------------------- | -----------
`SERVER_NAME` | The fully-qualified domain name for which we are requesting a certificate.
`CERTBOT_EMAIL` | The email address that should be used for communications about the certificate.

Additionally, container expects an nginx configuration file to be mounted to `/etc/nginx/custom.conf`. This
configuration file is included within the https `server` nginx block. See `https.conf` for the context.

# Usage
In the `example` directory a simple `docker-compose.yml` and `custom.conf` are provided that will launch an
`nginx-certbot-proxy` container that proxies all requests to another `nginx` container over http after terminating TLS.
The example can be run with the following command run from the `example` directory:

```bash
SERVER_NAME=foo.com CERTBOT_EMAIL=admin@foo.com docker-compose up --build
```

Be sure to replace `foo.com` and `admin@foo.com` with the actual values for your host.

If everything is successful then the `nginx-certbot-proxy` container should retreive a certificate through certbot, then
launch the https server. Once the https server is running, a request to `http://foo.com` will go to the
`nginx-certbot-proxy` container, and get a http `301` permanent redirect to `https://foo.com`. Then, once a request for
`https://foo.com` comes in, the `nginx-certbot-proxy` container will proxy the request to the `nginx` container
specified in the example.

That's it. One command and you're up and running, and you don't even have to modify any of the files in this repository.
