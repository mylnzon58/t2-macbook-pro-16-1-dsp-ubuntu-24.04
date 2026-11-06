#!/usr/bin/env bash
# ==============================================================================
# 1-Step GitHub Login, Public Repository Creation & GitHub Pages Deployment
# Author: mylnzon58 <mylnzon58@gmail.com>
# ==============================================================================
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${REPO_DIR}"

REPO_NAME="t2-macbook-pro-16-1-dsp-ubuntu-24.04"
DESC="MacBook Pro 16,1 (2019, A2141) 6-Channel Speaker DSP Fix for Ubuntu 24.04 LTS (PipeWire 1.0.7 LV2/LADSPA/FIR Convolver)"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

export PATH="${HOME}/.local/bin:/tmp:${PATH}"

echo -e "${CYAN}==> Preparing to publish ${REPO_NAME} to GitHub (mylnzon58@gmail.com)...${NC}"

# Ensure GitHub CLI (gh) is available (installs locally to ~/.local/bin without needing root)
if ! command -v gh &>/dev/null; then
    echo -e "${YELLOW}[!] Downloading official GitHub CLI (gh) to ~/.local/bin/gh...${NC}"
    mkdir -p "${HOME}/.local/bin"
    GH_VER="2.62.0"
    curl -fsSL "https://github.com/cli/cli/releases/download/v${GH_VER}/gh_${GH_VER}_linux_amd64.tar.gz" -o /tmp/gh.tar.gz
    tar -xzf /tmp/gh.tar.gz -C /tmp
    cp -f "/tmp/gh_${GH_VER}_linux_amd64/bin/gh" "${HOME}/.local/bin/gh"
    chmod +x "${HOME}/.local/bin/gh"
    rm -rf /tmp/gh.tar.gz "/tmp/gh_${GH_VER}_linux_amd64"
    echo -e "${GREEN}[✓] Installed GitHub CLI to ~/.local/bin/gh${NC}"
fi

# Authenticate if not logged in
if ! gh auth status &>/dev/null; then
    echo -e "${CYAN}==> Opening browser for GitHub authentication (mylnzon58@gmail.com)...${NC}"
    printf '\n' | gh auth login -h github.com -p https -w
fi

GH_USER="$(gh api user -q .login)"
echo -e "${GREEN}[✓] Authenticated as GitHub user: @${GH_USER} (mylnzon58@gmail.com)${NC}"

# Ensure git author matches user identity
git config user.name "${GH_USER}"
git config user.email "mylnzon58@gmail.com"
gh auth setup-git

# If GitHub handle differs from default placeholder 'mylnzon58', sync URLs in docs & README
if [[ "${GH_USER}" != "mylnzon58" ]]; then
    sed -i "s|github.com/mylnzon58|github.com/${GH_USER}|g" README.md docs/index.html
    sed -i "s|mylnzon58.github.io|${GH_USER}.github.io|g" docs/robots.txt docs/sitemap.xml
    git add README.md docs/index.html docs/robots.txt docs/sitemap.xml
    git commit --amend --no-edit --reset-author
fi

# Create public repository and push main branch
if gh repo view "${GH_USER}/${REPO_NAME}" &>/dev/null; then
    echo -e "${CYAN}[i] Repository ${GH_USER}/${REPO_NAME} already exists. Pushing main...${NC}"
    git remote set-url origin "https://github.com/${GH_USER}/${REPO_NAME}.git" 2>/dev/null || \
        git remote add origin "https://github.com/${GH_USER}/${REPO_NAME}.git"
    git push -u origin main --force
else
    echo -e "${CYAN}==> Creating public repository ${GH_USER}/${REPO_NAME} and pushing commits...${NC}"
    gh repo create "${REPO_NAME}" --public --source=. --remote=origin --description "${DESC}" --push
fi

# Add SEO topics to the GitHub repository
echo -e "${CYAN}==> Setting GitHub SEO repository topics & homepage...${NC}"
gh repo edit "${GH_USER}/${REPO_NAME}" \
    --homepage "https://${GH_USER}.github.io/${REPO_NAME}/" \
    --add-topic "ubuntu-24-04" \
    --add-topic "t2-linux" \
    --add-topic "macbook-pro" \
    --add-topic "pipewire" \
    --add-topic "audio-dsp" \
    --add-topic "lv2" \
    --add-topic "apple-t2" \
    --add-topic "linux-audio" || true

# Enable GitHub Pages via API (deploy from main branch /docs folder)
echo -e "${CYAN}==> Activating GitHub Pages from main:/docs...${NC}"
gh api -X POST "repos/${GH_USER}/${REPO_NAME}/pages" \
    -f "source[branch]=main" -f "source[path]=/docs" 2>/dev/null || \
gh api -X PUT "repos/${GH_USER}/${REPO_NAME}/pages" \
    -f "source[branch]=main" -f "source[path]=/docs" 2>/dev/null || true

echo -e "\n${GREEN}======================================================================${NC}"
echo -e "${GREEN}[✓] Public Repository:${NC} https://github.com/${GH_USER}/${REPO_NAME}"
echo -e "${GREEN}[✓] Live Landing Page:${NC} https://${GH_USER}.github.io/${REPO_NAME}/"
echo -e "${GREEN}======================================================================${NC}"
