# Use neovim as the default editor for most applications that support this choice
export VISUAL=nvim
export EDITOR="$VISUAL"

source ~/.led_aliases.sh

alias kc="kubectl"
alias docker-compose="docker compose"
alias cat="batcat --color=always"

# K8s
alias ns="set_k8s_namespace"

function set_k8s_namespace() {
        kubectl config set-context --current --namespace="$1"
        echo "Set default namespace to $1"
}

