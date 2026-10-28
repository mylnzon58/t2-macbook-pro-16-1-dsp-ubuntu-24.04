#!/usr/bin/env bash
# ==============================================================================
# MacBook Pro 16,1 (2019, A2141) 6-Channel Speaker DSP Uninstaller
# Author: mylnzon58 <mylnzon58@gmail.com>
# ==============================================================================
set -euo pipefail

TARGET_CONF="${HOME}/.config/pipewire/pipewire.conf.d/10-t2_161_speakers.conf"

if [[ -f "${TARGET_CONF}" ]]; then
    mv -f "${TARGET_CONF}" "${TARGET_CONF}.disabled"
    echo "[✓] Disabled ${TARGET_CONF}"
fi

systemctl --user restart pipewire wireplumber pipewire-pulse
echo "[✓] Restarted PipeWire services. Standard raw audio output restored."
