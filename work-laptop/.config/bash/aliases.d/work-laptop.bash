# shellcheck shell=bash

# Turnkey/work-laptop commands. This file is loaded by ~/.bash_aliases only
# when the work-laptop Stow package is installed.
alias tf="terraform"
alias tk="tkinfra"
alias tkhq='cd "$HOME/tkhq/code"'
alias mono='cd "$HOME/tkhq/code/mono"'
alias sdk='cd "$HOME/tkhq/code/sdk"'

tk-create-local-user() {
  if [[ $# -lt 1 || -z "${1:-}" ]]; then
    echo "Usage: tk-create-local-user <email>" >&2
    return 2
  fi

  local email="$1"
  local email_file
  local signup_url="${TK_LOCAL_COORDINATOR_URL:-http://localhost:8081}/tkhq/api/v1/initial-signup"
  local magic_link
  local payload

  email_file="/tmp/tkpostoffice/$(printf '%s' "$email" | sha256sum | cut -d' ' -f1)"
  rm -f "$email_file"
  payload="$(jq -cn --arg email "$email" '{email: $email}')"

  if ! curl --fail-with-body --silent --show-error \
    --request POST "$signup_url" \
    --header 'Content-Type: application/json' \
    --data "$payload" >/dev/null; then
    echo "tk-create-local-user: signup request failed" >&2
    return 1
  fi

  local deadline=$((SECONDS + 30))
  while [[ ! -s "$email_file" ]]; do
    if (( SECONDS >= deadline )); then
      echo "tk-create-local-user: timed out waiting for the local magic link" >&2
      return 1
    fi
    sleep 1
  done

  magic_link="$(<"$email_file")"
  if [[ -z "$magic_link" ]]; then
    echo "tk-create-local-user: local magic-link file was empty" >&2
    return 1
  fi

  printf '%s\n' "$magic_link"
}

if [[ -r /usr/share/nvm/init-nvm.sh ]]; then
  # shellcheck source=/dev/null
  source /usr/share/nvm/init-nvm.sh
fi
