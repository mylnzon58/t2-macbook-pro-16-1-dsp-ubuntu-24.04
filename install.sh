#!/usr/bin/env bash
# ==============================================================================
# MacBook Pro 16,1 (2019, A2141) 6-Channel Speaker DSP Installer for Ubuntu 24.04
# Maintainer: mylnzon58 <mylnzon58@gmail.com>
# License: MIT
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
USER_PW_DIR="${HOME}/.config/pipewire/pipewire.conf.d"
TARGET_CONF="${USER_PW_DIR}/10-t2_161_speakers.conf"
SYS_CONF="/etc/pipewire/pipewire.conf.d/10-t2_161_speakers.conf"
LV2_MOD="/usr/lib/x86_64-linux-gnu/pipewire-0.3/libpipewire-module-filter-chain-lv2.so"
LADSPA_LIM="/usr/lib/ladspa/fast_lookahead_limiter_1913.so"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}==> [T2-DSP] MacBook Pro 16,1 (A2141) 6-Channel Speaker DSP Installer (Ubuntu 24.04 LTS)${NC}"
echo -e "${CYAN}==> Maintained by @mylnzon58 (mylnzon58@gmail.com)${NC}\n"

# 0. Verify Apple T2 Audio hardware (PCI 106b:1803)
T2_PCI_RAW="$(lspci -D -d 106b:1803 2>/dev/null | awk '{print $1; exit}' || true)"
if [[ -z "${T2_PCI_RAW}" ]]; then
    echo -e "${YELLOW}[!] Warning: Apple T2 Audio PCI device (106b:1803) not detected via lspci.${NC}"
    echo -e "${YELLOW}    Ensure you are running a T2 Linux kernel (https://wiki.t2linux.org).${NC}"
    T2_ALSA_TARGET="alsa_output.pci-0000_04_00.3.Speakers"
else
    T2_PCI_UNDERSCORE="${T2_PCI_RAW//:/_}"
    T2_ALSA_TARGET="alsa_output.pci-${T2_PCI_UNDERSCORE}.Speakers"
    echo -e "${GREEN}[✓] Detected Apple T2 Audio Controller at PCI ${T2_PCI_RAW} (${T2_ALSA_TARGET})${NC}"
fi

# 1. Check PipeWire LV2 module support
if [[ ! -f "${LV2_MOD}" ]]; then
    echo -e "${YELLOW}[!] PipeWire LV2 filter-chain module not found (${LV2_MOD}).${NC}"
    echo -e "${YELLOW}    Stock Ubuntu 24.04 PipeWire 1.0.5 is compiled with -Dlv2=disabled.${NC}"
    read -rp "    Add ppa:pipewire-debian/pipewire-upstream and upgrade PipeWire now? [Y/n] " ans
    ans="${ans:-Y}"
    if [[ "${ans}" =~ ^[Yy]$ ]]; then
        sudo add-apt-repository -y ppa:pipewire-debian/pipewire-upstream
        sudo apt-get update
        sudo apt-get install -y pipewire libpipewire-0.3-modules pipewire-pulse pipewire-alsa \
            libspa-0.2-modules wireplumber calf-plugins lsp-plugins-lv2 swh-plugins swh-lv2
    else
        echo -e "${RED}[x] Aborted. PipeWire >= 1.0.7 with LV2 support is required.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}[✓] Found PipeWire LV2 module: ${LV2_MOD}${NC}"
fi

# 2. Check required LV2 & LADSPA plugins (Calf BassEnhancer, LSP MB Compressor, SWH Fast Lookahead Limiter)
MISSING_PKGS=()
dpkg -s calf-plugins &>/dev/null || MISSING_PKGS+=("calf-plugins")
dpkg -s lsp-plugins-lv2 &>/dev/null || MISSING_PKGS+=("lsp-plugins-lv2")
[[ -f "${LADSPA_LIM}" ]] || MISSING_PKGS+=("swh-plugins")

if (( ${#MISSING_PKGS[@]} > 0 )); then
    echo -e "${YELLOW}[!] Installing missing DSP plugin packages: ${MISSING_PKGS[*]}${NC}"
    sudo apt-get update
    sudo apt-get install -y "${MISSING_PKGS[@]}"
else
    echo -e "${GREEN}[✓] Verified DSP plugins: calf-plugins, lsp-plugins-lv2, swh-plugins (${LADSPA_LIM})${NC}"
fi

# 3. Install 16,1 FIR impulse responses, 6-channel ALSA profile, mixer paths & udev rule
if [[ ! -f "/usr/share/pipewire/devices/apple/macbook_pro_t2_16_1_woofers_4-48k.wav" ]]; then
    echo -e "${YELLOW}[!] Installing MacBookPro16,1 FIR impulse responses to /usr/share/pipewire/devices/apple/...${NC}"
    sudo mkdir -p /usr/share/pipewire/devices/apple
    sudo cp -f "${REPO_DIR}"/fir/macbook_pro_t2_16_1_*.wav /usr/share/pipewire/devices/apple/
else
    echo -e "${GREEN}[✓] Verified FIR impulse responses in /usr/share/pipewire/devices/apple/${NC}"
fi

NEED_UDEV_RELOAD=0
if [[ ! -f "/usr/share/alsa-card-profile/mixer/profile-sets/apple-t2x6.conf" ]]; then
    echo -e "${YELLOW}[!] Installing 6-channel ALSA profile (apple-t2x6.conf)...${NC}"
    sudo mkdir -p /usr/share/alsa-card-profile/mixer/profile-sets
    sudo cp -f "${REPO_DIR}/config/alsa-card-profile/apple-t2x6.conf" /usr/share/alsa-card-profile/mixer/profile-sets/apple-t2x6.conf
    NEED_UDEV_RELOAD=1
fi

if [[ ! -f "/usr/share/alsa-card-profile/mixer/paths/t2-speakers.conf" ]]; then
    echo -e "${YELLOW}[!] Installing Apple T2 ALSA mixer paths (t2-*.conf)...${NC}"
    sudo mkdir -p /usr/share/alsa-card-profile/mixer/paths
    sudo cp -f "${REPO_DIR}"/config/alsa-card-profile/paths/t2-*.conf /usr/share/alsa-card-profile/mixer/paths/
    NEED_UDEV_RELOAD=1
fi

if [[ ! -f "/lib/udev/rules.d/91-audio-custom.rules" ]]; then
    echo -e "${YELLOW}[!] Installing Apple T2 audio udev rule (91-audio-custom.rules)...${NC}"
    sudo cp -f "${REPO_DIR}/config/udev/91-audio-custom.rules" /lib/udev/rules.d/91-audio-custom.rules
    NEED_UDEV_RELOAD=1
fi

if (( NEED_UDEV_RELOAD == 1 )); then
    sudo udevadm control --reload-rules && sudo udevadm trigger
fi

# 4. Disable any conflicting /etc/pipewire drop-in to avoid duplicate module loading
if [[ -f "${SYS_CONF}" ]]; then
    echo -e "${YELLOW}[!] Disabling legacy system config at ${SYS_CONF} (saved as .disabled)...${NC}"
    sudo mv -f "${SYS_CONF}" "${SYS_CONF}.disabled"
fi

# 5. Install patched PipeWire DSP config in user profile & match PCI target
mkdir -p "${USER_PW_DIR}"
if [[ -f "${TARGET_CONF}" ]]; then
    BACKUP="${TARGET_CONF}.bak-$(date +%Y%m%d-%H%M%S)"
    cp -a "${TARGET_CONF}" "${BACKUP}"
    echo -e "${CYAN}[i] Backed up existing user config to ${BACKUP}${NC}"
fi

cp -f "${REPO_DIR}/config/pipewire/10-t2_161_speakers.conf" "${TARGET_CONF}"
if [[ "${T2_ALSA_TARGET}" != "alsa_output.pci-0000_04_00.3.Speakers" ]]; then
    sed -i "s|alsa_output.pci-0000_04_00.3.Speakers|${T2_ALSA_TARGET}|g" "${TARGET_CONF}"
fi
echo -e "${GREEN}[✓] Installed patched DSP graph to ${TARGET_CONF}${NC}"

# 6. Restart PipeWire & WirePlumber user services
echo -e "${CYAN}==> Restarting PipeWire, WirePlumber, and PipeWire-Pulse...${NC}"
systemctl --user restart pipewire wireplumber pipewire-pulse
sleep 2

# 7. Calibrate hardware sink volume (100% / 0 dB) and select DSP sink (70%)
RAW_SINK_ID="$(wpctl status | awk '/Apple Audio Device Speakers/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.$/) {sub(/\./,"",$i); print $i; exit}}' || true)"
DSP_SINK_ID="$(wpctl status | awk '/MacBook Pro T2 DSP Speakers/ {for(i=1;i<=NF;i++) if($i ~ /^[0-9]+\.$/) {sub(/\./,"",$i); print $i; exit}}' || true)"

if [[ -n "${RAW_SINK_ID}" ]]; then
    wpctl set-volume "${RAW_SINK_ID}" 1.0
    echo -e "${GREEN}[✓] Set raw hardware sink (ID ${RAW_SINK_ID}: Apple Audio Device Speakers) to 100% (0 dB)${NC}"
fi

if [[ -n "${DSP_SINK_ID}" ]]; then
    wpctl set-default "${DSP_SINK_ID}"
    wpctl set-volume "${DSP_SINK_ID}" 0.70
    echo -e "${GREEN}[✓] Set 'MacBook Pro T2 DSP Speakers' (ID ${DSP_SINK_ID}) as Default Sink at 70% volume${NC}"
else
    echo -e "${RED}[x] DSP sink did not appear. Rolling back configuration to restore normal audio...${NC}"
    rm -f "${TARGET_CONF}"
    systemctl --user restart pipewire wireplumber pipewire-pulse
    exit 1
fi

echo -e "\n${GREEN}==> SUCCESS! 6-Channel Apple T2 DSP Audio is active and verified.${NC}"
echo -e "${CYAN}==> Repository & Documentation: https://github.com/mylnzon58/t2-macbook-pro-16-1-dsp-ubuntu-24.04${NC}"
