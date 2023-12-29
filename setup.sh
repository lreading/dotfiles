#!/bin/bash

warning_confirmed=0

function confirm_warning() {
    if [ $warning_confirmed == 1 ]; then
        return
    fi

    # Borrowed from https://stackoverflow.com/a/1885534
    read -p "Running this will remove the existing config and overwrite it with the dotfile(s) in this repo.  Are you sure you want to continue? [Y/n] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        [[ "$0" = "$BASH_SOURCE" ]] && exit 1 || return 1
    fi
    warning_confirmed=1
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

function install_packer() {
    git clone --depth 1 https://github.com/wbthomason/packer.nvim \
        ~/.local/share/nvim/site/pack/packer/start/packer.nvim
}

function install_dependencies() {
    install_apt_packages
    install_neovim
    install_packer
}

function nvim_config() {
    confirm_warning
    mkdir -p ~/.config/
    cp -r ./nvim/* ~/.config/nvim/
}

function tmux_config() {
    confirm_warning
    cp ./.tmux.conf ~/.tmux.conf
    chmod 0600 ~/.tmux.conf
}

function aliases_config() {
    confirm_warning

    cp ./.bashpromptrc ~/.bashpromptrc
    chmod 0600 ~/.bashpromptrc

    cp ./.bash_aliases ~/.bash_aliases
    chmod 0600 ~/.bash_aliases
}

function conky_config() {
    confirm_warning

    cp ./.conkyrc ~/.conkyrc
    chmod 0600 ~/.conkyrc
    
    mkdir -p ~/.config/autostart
    cp ./conky.desktop ~/.config/autostart/conky.desktop
}

function print_help() {
    echo "./setup.sh [deps|nvim|tmux|aliases|conky|all]"
}


if [ $# -lt 1 ]; then
    echo "Argument required:"
    print_help
    exit 1
fi


for arg in "$@"
do
    case $arg in
        deps)
            install_dependencies
            shift
            ;;
        nvim)
            nvim_config
            shift
            ;;
        tmux)
            tmux_config
            shift
            ;;
        aliases)
            aliases_config
            shift
            ;;
        conky)
            conky_config
            shift
            ;;
        all)
            install_dependencies
            nvim_config
            tmux_config
            aliases_config
            conky_config
            shift
            ;;
        help)
            print_help
            shift
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg"
            print_help
            exit 1
            ;;
    esac
done

