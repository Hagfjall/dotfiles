FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
# Use Swedish APT mirror (Bahnhof)
RUN sed -i -e 's@archive.ubuntu.com@mirror.bahnhof.net/ubuntu@g' -e 's@security.ubuntu.com@mirror.bahnhof.net/ubuntu@g' /etc/apt/sources.list.d/ubuntu.sources
RUN apt-get update && apt-get install -y fish git sudo ca-certificates curl
COPY home/ /opt/dotfiles/home/
COPY scripts/ /opt/dotfiles/scripts/
COPY apps/ /opt/dotfiles/apps/
COPY install.sh /opt/dotfiles/install.sh
WORKDIR /opt/dotfiles

RUN ["/opt/dotfiles/install.sh"]

RUN test -L /root/.config/fish/conf.d/aliases.fish
RUN test -L /root/.tmux.conf
SHELL ["/bin/fish", "-c"]

ENTRYPOINT ["/bin/fish", "-c"]

