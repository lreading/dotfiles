#!/usr/bin/env bash


# NOTE: Never print to stdout using echo.  All errors must be printed
# to stderr, otherwise the wrapper script will crash and burn.


# These can be directories or files
# They are only copied if they exist
# Any other commonly ignored patterns that you want to copy
# to a git worktree can be added to this array
COPY_PATHS=(
  "agents"
  ".codex"
  "AGENTS.md"
  "docs"
)


echo_stderr() {
  echo "$@" >&2
}


print_help() {
  echo_stderr "This is a wrapper script for the git worktree command"
  echo_stderr
  echo_stderr "Usage:"
  echo_stderr "  git-worktree <branch>"
  echo_stderr
  echo_stderr "The branch may include '/' which will be included in the path"
  echo_stderr "The CWD is always used, there is no target dir"
  echo_stderr
  echo_stderr "Example:"
  echo_stderr "  git-worktree feat/fix-shit"
  echo_stderr
  echo_stderr "This will create a new local branch named feat/fix-shit and"
  echo_stderr "  create a new git worktree in ../<cwd-name>-worktrees/<branch>"
}


print_error() {
  echo_stderr "ERROR:"
  echo_stderr "  [!] - $1"
}


validate_branch_name() {
  if [[ -z "$1" ]]; then
    print_help
    exit 1
  fi

  if ! git check-ref-format --branch "$1" 2>/dev/null; then
    print_error "$1 is not a valid git branch name."
    exit 1
  fi
}


set_pwd_to_repo_root() {
  local src_root
  if ! src_root=$(git rev-parse --show-toplevel 2>/dev/null); then
    print_help
    print_error "You are not in a valid git repository."
    exit 1
  fi

  cd "$src_root"
}


create_git_worktree() {
  local branch_name="$1"
  local worktree_location="$2"

  if git show-ref --verify --quiet "refs/heads/$branch_name"; then
    git worktree add "$worktree_location" "$branch_name" || return 1
  else
    git worktree add -b "$branch_name" "$worktree_location" || return 1
  fi
}


copy_untracked_files() {
  local repo_root_dir="$1"
  local worktree_dir="$2"

  for path in "${COPY_PATHS[@]}"; do
    local src="$repo_root_dir/$path"

    if [[ -e "$src" ]]; then
      cp -R "$src" "$worktree_dir/"
    fi
  done
}


main() {
  local branch_name="$1"
  local repo_basename
  local repo_root_dir
  local worktree_dir

  validate_branch_name "$branch_name" || return 1
  set_pwd_to_repo_root || return 1

  repo_basename="$(basename "$PWD")"
  repo_root_dir="$PWD"
  worktree_dir="../$repo_basename-worktrees/$branch_name"

  mkdir -p "$worktree_dir" || {
    print_error "Failed to create worktree directory"
    return 1
  }

  if ! create_git_worktree "$branch_name" "$worktree_dir"; then
    print_error "git worktree add failed"
    return 1
  fi

  copy_untracked_files "$repo_root_dir" "$worktree_dir"

  # CRITICAL: LAST LINE ONLY = PATH
  # Used by wrapper in ~/.bash_alias with `tail -n1` to cd into the worktree
  realpath "$worktree_dir"
}


main "$@" || exit 1

