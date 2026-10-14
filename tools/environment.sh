#!/usr/bin/env bash
# Source this file. Keep machine-specific editor data outside the repository.
if [[ -d /workspace ]]; then
  export FERAL_STATE_ROOT="${FERAL_STATE_ROOT:-/workspace}"
else
  export FERAL_STATE_ROOT="${FERAL_STATE_ROOT:-$HOME}"
fi
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$FERAL_STATE_ROOT/.cache}"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$FERAL_STATE_ROOT/.config}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$FERAL_STATE_ROOT/.local/share}"
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-$XDG_CACHE_HOME/ms-playwright}"
export PATH="$FERAL_STATE_ROOT/.local/bin:$PATH"
mkdir -p "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME"
