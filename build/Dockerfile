FROM archlinux:latest@sha256:d3bf5ee8ab6200d30fe5366a64b46151f434f6dd0cf8b271297b2e32fc8f6191 AS terraform

RUN pacman -Sy --noconfirm \
    terraform \
    unzip

RUN curl --location \
    --output /tmp/tflint.zip \
    https://github.com/terraform-linters/tflint/releases/download/v0.37.0/tflint_linux_amd64.zip
RUN unzip -d /usr/local/bin /tmp/tflint.zip

WORKDIR /repo
VOLUME /repo
