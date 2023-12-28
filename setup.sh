#!/bin/bash

# Borrowed from https://stackoverflow.com/a/1885534
read -p "Running this will remove existing configs and overwrite them with the dotfiles in this repo.  Are you sure you want to continue?" -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
fi

function copy_dot_files() {
    cp ./.tmux.conf ~/.tmux.conf
    chmod 0600 ~/.tmux.conf

    cp ./.bashpromptrc ~/.bashpromptrc
    chmod 0600 ~/.bashpromptrc

    cp ./.bash_aliases ~/.bash_aliases
    chmod 0600 ~/.bash_aliases

    cp ./.conkyrc ~/.conkyrc
    chmod 0600 ~/.conkyrc

    mkdir -p ~/.config/
    cp -r ./nvim ~/.config/nvim
}

function install_apt_packages() {
    sudo apt-get install -y \
        tmux \
        fuse \
        libfuse2 \
        curl \
        conky-all
}

function install_neovim() {
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
}

copy_dot_files
install_apt_packages
install_neovim

