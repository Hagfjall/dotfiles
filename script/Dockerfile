FROM ubuntu:latest

RUN apt update \
    && apt install curl

RUN  sh -c "$(curl -fsSL https://raw.githubusercontent.com/Hagfjall/dotfiles/refs/heads/master/script/bootstrap)" 