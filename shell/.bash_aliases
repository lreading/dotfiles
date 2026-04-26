export VISUAL=nvim
export EDITOR="$VISUAL"

alias x="clear"
alias ll="ls -lah"
alias kc="kubectl"

# Bash Completion for the kubectl alias
complete -o default -F __start_kubectl kc
alias docker-compose="docker compose"

# K8s
alias ns="set_k8s_namespace"

function set_k8s_namespace() {
        kubectl config set-context --current --namespace="$1"
        echo "Set default namespace to $1"
}

__k8s_ns_complete() {
  local cur
  cur="${COMP_WORDS[COMP_CWORD]}"

  local nss
  nss="$(kubectl get ns -o jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}' 2>/dev/null)"

  COMPREPLY=( $(compgen -W "$nss" -- "$cur") )
}

# Attach completion to BOTH the function and the alias name
complete -F __k8s_ns_complete set_k8s_namespace
complete -F __k8s_ns_complete ns

# I'm impatient, this probably isn't the best
alias reconcile-flux="flux reconcile kustomization flux-system --with-source"

function flux-dry-run() {
  if [ -z "$1" ]; then
    echo "Usage: flux-dry-run <path-to-kustomize-dir>"
    return 1
  fi
  kustomize build --load-restrictor=LoadRestrictionsNone "$1" | kubectl apply --server-side --dry-run=server -f -
}


# I always forget how to build just the appimage
# The other packages don't work well on Arch
alias td-build-desktop="npm run build:desktop -- --linux appimage --x64"

# Wrapper function for ~/.local/bin/git-worktree-helper.sh
# Running without args will print the help
git-worktree() {
  local dir

  if ! dir="$(command git-worktree-helper.sh "$@" | tail -n1)"; then
    return 1
  fi

  if [[ -z "$dir" ]]; then
    return 1
  fi

  if [[ ! -d "$dir" ]]; then
    return 1
  fi

  cd "$dir"
}
