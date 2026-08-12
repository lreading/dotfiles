# shellcheck shell=bash

# Turnkey/work-laptop commands. This file is loaded by ~/.bash_aliases only
# when the work-laptop Stow package is installed.
alias tf="terraform"
alias tk="tkinfra"
alias tkhq='cd "$HOME/tkhq/code"'
alias mono='cd "$HOME/tkhq/code/mono"'
alias sdk='cd "$HOME/tkhq/code/sdk"'

if [[ -r /usr/share/nvm/init-nvm.sh ]]; then
  # shellcheck source=/dev/null
  source /usr/share/nvm/init-nvm.sh
fi
