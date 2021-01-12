#!/bin/bash

set -e
type docker || { curl -sSL https://get.docker.com | sh; sudo usermod -aG docker pi; exec bash; }

type docker-compose || sudo apt-get install -y docker-compose


cat << EOF > prometheus.yml
global:
  scrape_interval:     10s
  evaluation_interval: 10s
scrape_configs:
  - job_name: 'prometheus'
    static_configs:
         - targets: [ 'localhost:9090', ]
EOF

cat << EOF > Dockerfile-prometheus
FROM arm32v6/alpine:3.5
RUN apk add --update -t curl
WORKDIR /bin
RUN curl -L --silent -o prometheus-2.24.0.linux-armv6.tar.gz https://github.com/prometheus/prometheus/releases/download/v2.24.0/prometheus-2.24.0.linux-armv6.tar.gz && \
    tar -xzf prometheus-2.24.0.linux-armv6.tar.gz --strip 1
EXPOSE 9090
ENTRYPOINT ["/bin/prometheus"]
CMD ["--config.file=/etc/prometheus/prometheus.yml" "--storage.tsdb.path=/prometheus" "--web.console.libraries=/usr/share/prometheus/console_libraries"
EOF

cat << EOF > docker-compose.yml
version: '3'
services:
  prometheus:
    build:
      context: .
      dockerfile: Dockerfile-prometheus
    logging:
      driver: "json-file"
      options:
        max-size: 500m
    restart: always
    volumes:
      - ./prometheus.yml:/etc/prometheus/prometheus.yml
      - ./prometheus:/prometheus
    command:
      - '--storage.tsdb.path=/prometheus'
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.retention=90d'
    ports:
      - 9090:9090
EOF

docker-compose up -d --build
