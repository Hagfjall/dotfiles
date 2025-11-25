FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
# Use Swedish APT mirror (Bahnhof)
RUN echo "deb http://mirror.bahnhof.net/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://mirror.bahnhof.net/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirror.bahnhof.net/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirror.bahnhof.net/ubuntu/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list
COPY home/ /opt/dotfiles/home/
COPY scripts/ /opt/dotfiles/scripts/
COPY install.sh /opt/dotfiles/install.sh
WORKDIR /opt/dotfiles

RUN ["/opt/dotfiles/install.sh"]

RUN test -L /root/.config/fish/conf.d/aliases.fish
SHELL ["/bin/fish", "-c"]

ENTRYPOINT ["/bin/fish", "-c"]

