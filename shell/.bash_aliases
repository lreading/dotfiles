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

td-trivy-check() {
  local repo_dir="${TD_REPO_DIR:-}"
  local image="${TD_TRIVY_IMAGE:-threat-dragon:trivy-check}"
  local remote_url
  local normalized_remote
  local current_repo_dir

  if [[ -z "$repo_dir" ]] && current_repo_dir="$(git rev-parse --show-toplevel 2>/dev/null)"; then
    repo_dir="$current_repo_dir"
  fi

  repo_dir="${repo_dir:-$HOME/dev/threat-dragon}"

  if [[ ! -d "$repo_dir" ]] || ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "td-trivy-check: not a git checkout: $repo_dir" >&2
    return 2
  fi

  remote_url="$(git -C "$repo_dir" remote get-url origin 2>/dev/null)" || {
    echo "td-trivy-check: unable to read origin remote in $repo_dir" >&2
    return 2
  }

  normalized_remote="${remote_url,,}"
  normalized_remote="${normalized_remote#git@github.com:}"
  normalized_remote="${normalized_remote#https://github.com/}"
  normalized_remote="${normalized_remote#ssh://git@github.com/}"
  normalized_remote="${normalized_remote%.git}"

  if [[ "$normalized_remote" != "owasp/threat-dragon" ]]; then
    echo "td-trivy-check: expected origin remote OWASP/threat-dragon, got $remote_url" >&2
    return 2
  fi

  if [[ ! -f "$repo_dir/.github/workflows/.trivyignore" ]]; then
    echo "td-trivy-check: missing $repo_dir/.github/workflows/.trivyignore" >&2
    return 2
  fi

  (
    cd "$repo_dir" || exit 2
    docker build --platform linux/amd64 -t "$image" .
    trivy-check \
      --ignore-file .github/workflows/.trivyignore \
      --fail-on 'CRITICAL,HIGH' \
      --skip-files '/app/docs/configure/bitbucket.html,/app/docs/assets/search.json' \
      "$image"
  )
}
export -f td-trivy-check

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

alias kill-ferdium="kill -9 $(ps aux | grep ferdium | head -n 1 | awk '{ print $2 }')"

_td_e2e() {
  (
    cd /home/leo/dev/threat-dragon-worktrees/bugfix/reverse-proxy-escaping/td.vue || exit 2
    npx vue-cli-service test:e2e -C e2e.local.config.js --headless --browser chromium "$@"
  )
}
alias td-e2e='_td_e2e'
