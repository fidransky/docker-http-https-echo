FROM node:16-alpine AS build

WORKDIR /app
COPY . /app

RUN set -ex \
  && npm install --production \
  && apk --no-cache add openssl \
  && openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout privkey.pem -out fullchain.pem \
       -subj "/C=GB/ST=London/L=London/O=Mendhak/CN=my.example.com" \
       -addext "subjectAltName=DNS:my.example.com,DNS:my.example.net,IP:192.168.50.108,IP:127.0.0.1" \
  && apk del openssl \
  && rm -rf /var/cache/apk/* \
  && rm package* \
  && chmod +r /app/privkey.pem

FROM node:16-alpine AS final
LABEL \
    org.opencontainers.image.title="http-https-echo" \
    org.opencontainers.image.description="Docker image that echoes request data as JSON; listens on HTTP/S, with various extra features, useful for debugging." \
    org.opencontainers.image.url="https://github.com/mendhak/docker-http-https-echo" \
    org.opencontainers.image.documentation="https://github.com/mendhak/docker-http-https-echo/blob/master/README.md" \
    org.opencontainers.image.source="https://github.com/mendhak/docker-http-https-echo" \
    org.opencontainers.image.licenses="MIT"
WORKDIR /app
COPY --from=build /app /app
ENV HTTP_PORT=8080 HTTPS_PORT=8443
EXPOSE $HTTP_PORT $HTTPS_PORT
RUN chgrp -R 0 /app && \
    chmod -R g=u /app
USER 1000
CMD ["node", "./index.js"]
