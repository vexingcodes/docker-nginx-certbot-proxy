FROM debian
RUN apt-get update \
 && apt-get install --yes --no-install-recommends \
      certbot \
      gettext \
      nginx \
      supervisor \
 && rm -rf /var/lib/apt/lists/*
ADD https://raw.githubusercontent.com/certbot/certbot/master/certbot-nginx/certbot_nginx/_internal/tls_configs/options-ssl-nginx.conf /etc/nginx/options-ssl-nginx.conf
ADD https://raw.githubusercontent.com/certbot/certbot/master/certbot/certbot/ssl-dhparams.pem /etc/nginx/ssl-dhparams.pem
COPY run-nginx run-certbot /usr/local/bin/
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY nginx.conf https.conf /tmp/nginx/
ENTRYPOINT ["supervisord", "-c", "/etc/supervisor/supervisord.conf"]
EXPOSE 80
EXPOSE 443
VOLUME /etc/nginx/custom.conf
VOLUME /etc/letsencrypt
