FROM caddy:2-alpine

COPY *.html /srv/
COPY css/ /srv/css/
COPY img/ /srv/img/
COPY Caddyfile /etc/caddy/Caddyfile
