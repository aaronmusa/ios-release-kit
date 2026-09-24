#!/bin/sh
#
# Symlinks this repo's hooks into .git/hooks. Run once after cloning.
#
# If you also set core.hooksPath globally, git stops looking in .git/hooks
# entirely and everything installed here silently stops running. A global
# hooks directory has to chain to the repo's own hook to keep both working:
#
#   repo_hook="$(git rev-parse --git-common-dir)/hooks/${0##*/}"
#   [ -x "$repo_hook" ] && exec "$repo_hook" "$@"
#
# Check with: git config --global --get core.hooksPath

set -e

root=$(git rev-parse --show-toplevel)
hooks=$(git rev-parse --git-common-dir)
case "$hooks" in /*) ;; *) hooks="$root/$hooks" ;; esac
mkdir -p "$hooks/hooks"

source_dir="$root/hooks"
[ -d "$source_dir" ] || source_dir="$root/scripts/git-hooks"
[ -d "$source_dir" ] || { echo "no hooks directory found" >&2; exit 1; }

for hook in "$source_dir"/*; do
  name=$(basename "$hook")
  case "$name" in install-hooks.sh) continue ;; esac
  ln -sfn "$hook" "$hooks/hooks/$name"
  chmod +x "$hook"
  echo "installed $name"
done

global=$(git config --global --get core.hooksPath || true)
if [ -n "$global" ]; then
  echo
  echo "note: core.hooksPath is set globally to $global"
  echo "these hooks only run if that dispatcher chains to .git/hooks"
fi
