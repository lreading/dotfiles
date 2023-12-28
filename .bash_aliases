# Use neovim as the default editor for most applications that support this choice
export VISUAL=nvim
export EDITOR="$VISUAL"

alias kc="kubectl"
alias docker-compose="docker compose"

# LED Control Stuff for desktop, requires liquidctl
alias doggo="sudo liquidctl set lcd screen gif /home/leo/Downloads/doge.gif --match kraken"
alias doggo-be-gone="sudo liquidctl set lcd screen liquid --match kraken"
alias led-blue="sudo liquidctl set led1 color fixed 0000FF --match smart"

# K8s
alias k8s-skunk="cp ~/.kube/skunk ~/.kube/config"
alias k8s-homelab="cp ~/.kube/homelab ~/.kube/config"
alias k8s-homelab-admin="cp ~/.kube/homelab-admin ~/.kube/config"
alias ns="set_k8s_namespace"

function set_k8s_namespace() {
        kubectl config set-context --current --namespace="$1"
        echo "Set default namespace to $1"
}

# This is another "dot file" that changes too frequently to keep it in source control
# and will be different depending on what machine it's on
if [ -f ~/.project_runners ]; then
    . ~/.project_runners
fi

# Bash prompt configuration
if [ -f ~/.bashpromptrc ]; then
    . ~/.bashpromptrc
fi
