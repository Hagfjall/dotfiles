FROM ubuntu:latest

RUN apt update \
    && apt install -y \
        curl \
        zsh \
        git \
    && rm -rf /var/lib/{apt,cache,log}

RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
