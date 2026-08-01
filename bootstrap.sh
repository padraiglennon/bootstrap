#!/usr/bin/env bash
# Runs as `coder` from /bootstrap every time the workspace starts.
set -euo pipefail

PACKAGES=(ripgrep fd-find jq tree htop curl atop)

# Without this, a package that asks a configuration question waits for an answer
# that never comes, and the 10-minute timeout kills the whole script.
export DEBIAN_FRONTEND=noninteractive

# This runs on every start, so skip the slow path when there is nothing to do.
missing=()
for pkg in "${PACKAGES[@]}"; do
    if ! dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -q '^install ok installed$'; then
        missing+=("$pkg")
    fi
done

if [ ${#missing[@]} -eq 0 ]; then
    echo "all ${#PACKAGES[@]} packages already installed"
else
    echo "installing: ${missing[*]}"
    sudo apt-get update -y
    sudo apt-get install -y --no-install-recommends "${missing[@]}"
fi

# Debian ships fd as `fdfind` to avoid a name clash. Symlink it to the name the
# documentation everywhere else uses. Written as an `if` and not `[ ... ] && ...`
# because under `set -e` a trailing test that fails would exit the whole script.
if [ -x /usr/bin/fdfind ]; then
    mkdir -p "$HOME/.local/bin"
    ln -sf /usr/bin/fdfind "$HOME/.local/bin/fd"
fi

echo "bootstrap finished"
