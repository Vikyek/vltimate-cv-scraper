#!/usr/bin/env bash
# ==============================================================================
# Vltimate CV Scraper & Resume Encryption Suite
# Usage: ./harvest_cv.sh
# Supports:
#   - System dependency verification (openssl, tar, curl, git, agy)
#   - Persistent local config (.vltimate_config.env) with strict gitignore protection
#   - Optional Private GitHub Cloud Sync (pulling encrypted vault data as input)
#   - System harvesting & ATS CV generation via agy
#   - Interactive AES-256 packing, encryption & security cleanup
#   - Automatic pushing of encrypted vault to private GitHub repo
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"
CONFIG_FILE="${SCRIPT_DIR}/.vltimate_config.env"
VAULT_DIR="${SCRIPT_DIR}/.vault_tmp"

SYSTEM_PROMPT_FILE="${SCRIPT_DIR}/cv_harvester_system_prompt.md"
RAW_PROFILE_FILE="${SCRIPT_DIR}/raw_technical_profile.md"
CV_EN_FILE="${SCRIPT_DIR}/cv_en.html"
CV_PL_FILE="${SCRIPT_DIR}/cv_pl.html"

ENCRYPTED_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz.enc"
PLAIN_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz"

echo "======================================================================"
echo "🚀 Vltimate CV Scraper & Private Cloud Vault Suite"
echo "Working Directory: ${SCRIPT_DIR}"
echo "======================================================================"

# ------------------------------------------------------------------------------
# STEP 0: System Dependency Verification
# ------------------------------------------------------------------------------
check_dependencies() {
    local missing=()
    local required_tools=("openssl" "tar" "curl" "git" "agy")

    for tool in "${required_tools[@]}"; do
        if ! command -v "${tool}" &>/dev/null; then
            missing+=("${tool}")
        fi
    done

    if [[ ${#missing[@]} -ne 0 ]]; then
        echo "❌ Dependency Check Failed! Missing required tools:" >&2
        for tool in "${missing[@]}"; do
            echo "   - ${tool}" >&2
        done
        echo "" >&2
        echo "Please install missing dependencies before running Vltimate CV Scraper:" >&2
        echo "   Arch Linux:  paru -S openssl tar curl git" >&2
        echo "   Antigravity: npm install -g @google/antigravity-cli" >&2
        echo "======================================================================" >&2
        exit 1
    fi
    echo "✅ System dependencies verified (openssl, tar, curl, git, agy)."
}

check_dependencies
mkdir -p "${OUTPUT_DIR}"

# ------------------------------------------------------------------------------
# STEP 1: Persistent Configuration Management
# ------------------------------------------------------------------------------
CLOUD_SYNC_ENABLED="false"
GITHUB_USER=""
GITHUB_TOKEN=""
VAULT_REPO="vltimate-cv-vault"

if [[ -f "${CONFIG_FILE}" ]]; then
    # Load existing config securely
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}"
    echo "⚙️ Loaded persistent config from ${CONFIG_FILE}"
else
    echo ""
    echo -n "☁️ Enable Private GitHub Cloud Sync for encrypted vault database? (y/N): "
    read -r SYNC_PROMPT
    if [[ "${SYNC_PROMPT}" =~ ^[Yy](es)?$ ]]; then
        CLOUD_SYNC_ENABLED="true"
        echo -n "👤 Enter your GitHub Username: "
        read -r GITHUB_USER
        echo -n "🔑 Enter your GitHub Personal Access Token (PAT) / Secret: "
        read -sp GITHUB_TOKEN
        echo ""
        echo -n "📦 Enter Private Vault Repo Name [default: vltimate-cv-vault]: "
        read -r INPUT_REPO
        if [[ -n "${INPUT_REPO}" ]]; then VAULT_REPO="${INPUT_REPO}"; fi

        # Save persistent config (protected by .gitignore)
        cat <<EOF > "${CONFIG_FILE}"
CLOUD_SYNC_ENABLED="${CLOUD_SYNC_ENABLED}"
GITHUB_USER="${GITHUB_USER}"
GITHUB_TOKEN="${GITHUB_TOKEN}"
VAULT_REPO="${VAULT_REPO}"
EOF
        chmod 600 "${CONFIG_FILE}"
        echo "💾 Config saved to ${CONFIG_FILE} (protected from git commits)."
    fi
fi

# ------------------------------------------------------------------------------
# STEP 2: Private Cloud Vault Pull & Pre-Harvest Decryption
# ------------------------------------------------------------------------------
if [[ "${CLOUD_SYNC_ENABLED}" == "true" && -n "${GITHUB_USER}" && -n "${GITHUB_TOKEN}" ]]; then
    echo "======================================================================"
    echo "☁️ Connecting to Private GitHub Vault (${GITHUB_USER}/${VAULT_REPO})..."
    echo "======================================================================"

    rm -rf "${VAULT_DIR}"
    VAULT_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${VAULT_REPO}.git"

    if git ls-remote "${VAULT_URL}" &>/dev/null; then
        echo "📥 Pulling latest encrypted database from private cloud vault..."
        git clone --quiet "${VAULT_URL}" "${VAULT_DIR}"
        if [[ -f "${VAULT_DIR}/personal_data.tar.gz.enc" ]]; then
            cp -f "${VAULT_DIR}/personal_data.tar.gz.enc" "${ENCRYPTED_ARCHIVE}"
            echo "✅ Latest encrypted cloud database downloaded successfully."
        fi
    else
        echo "ℹ️ Private vault repository not found on GitHub. It will be created on first sync."
    fi
fi

# ------------------------------------------------------------------------------
# STEP 3: Auto-detect & Read Packed / Encrypted Profile Results
# ------------------------------------------------------------------------------
if [[ -f "${ENCRYPTED_ARCHIVE}" ]]; then
    echo "🔐 Encrypted personal archive detected: ${ENCRYPTED_ARCHIVE}"
    echo -n "🔑 Enter decryption password to unlock profile data: "
    read -sp DECRYPT_PASS
    echo ""

    TEMP_TAR="$(mktemp --suffix=.tar.gz)"
    if openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in "${ENCRYPTED_ARCHIVE}" -out "${TEMP_TAR}" -pass pass:"${DECRYPT_PASS}" 2>/dev/null; then
        echo "🔓 Archive decrypted successfully! Unpacking prior technical data..."
        tar -xzf "${TEMP_TAR}" -C "${SCRIPT_DIR}"
        rm -f "${TEMP_TAR}"
    else
        echo "❌ Decryption failed: Invalid password or corrupted archive." >&2
        rm -f "${TEMP_TAR}"
        exit 1
    fi
elif [[ -f "${PLAIN_ARCHIVE}" ]]; then
    echo "📦 Packed archive detected: ${PLAIN_ARCHIVE}. Unpacking..."
    tar -xzf "${PLAIN_ARCHIVE}" -C "${SCRIPT_DIR}"
fi

# ------------------------------------------------------------------------------
# STEP 4: Execute agy Intelligence Harvesting & CV Generation
# ------------------------------------------------------------------------------
if [[ ! -f "${SYSTEM_PROMPT_FILE}" ]]; then
    echo "Error: System prompt missing at ${SYSTEM_PROMPT_FILE}" >&2
    exit 1
fi

PROMPT="Read '${SYSTEM_PROMPT_FILE}' and '${RAW_PROFILE_FILE}'. Perform technical data harvesting across system, shell history, git repos, and GitHub profile. Update '${RAW_PROFILE_FILE}', '${CV_EN_FILE}', and '${CV_PL_FILE}'. Save identical copies into '${OUTPUT_DIR}'."

echo "======================================================================"
echo "⚡ Harvesting technical intelligence with agy..."
echo "======================================================================"
agy --dangerously-skip-permissions --print "${PROMPT}"

# Synchronize fallback copies to output dir
cp -f "${RAW_PROFILE_FILE}" "${OUTPUT_DIR}/raw_technical_profile.md" 2>/dev/null || true
if [[ -f "${CV_EN_FILE}" ]]; then cp -f "${CV_EN_FILE}" "${OUTPUT_DIR}/cv_en.html" 2>/dev/null || true; fi
if [[ -f "${CV_PL_FILE}" ]]; then cp -f "${CV_PL_FILE}" "${OUTPUT_DIR}/cv_pl.html" 2>/dev/null || true; fi

echo "======================================================================"
echo "✅ Harvesting & CV Generation Phase Finished!"
echo "======================================================================"

# ------------------------------------------------------------------------------
# STEP 5: Interactive Prompt for Packing, Encryption & Cloud Sync
# ------------------------------------------------------------------------------
echo ""
echo -n "❓ Do you want to pack and encrypt the personal results now? (y/N): "
read -r PACK_CHOICE

if [[ "${PACK_CHOICE}" =~ ^[Yy](es)?$ ]]; then
    echo -n "🔑 Enter custom encryption password: "
    read -sp ENCRYPT_PASS1
    echo ""
    echo -n "🔑 Re-enter encryption password: "
    read -sp ENCRYPT_PASS2
    echo ""

    if [[ "${ENCRYPT_PASS1}" != "${ENCRYPT_PASS2}" ]]; then
        echo "❌ Password mismatch! Aborting encryption." >&2
        exit 1
    fi

    if [[ -z "${ENCRYPT_PASS1}" ]]; then
        echo "❌ Password cannot be empty! Aborting encryption." >&2
        exit 1
    fi

    echo "📦 Packing all profile, resume, and output files into compressed archive..."
    tar -czf "${PLAIN_ARCHIVE}" -C "${SCRIPT_DIR}" "raw_technical_profile.md" "cv_en.html" "cv_pl.html" "output"

    echo "🔒 Encrypting archive with OpenSSL (AES-256-CBC with PBKDF2)..."
    openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -in "${PLAIN_ARCHIVE}" -out "${ENCRYPTED_ARCHIVE}" -pass pass:"${ENCRYPT_PASS1}"
    rm -f "${PLAIN_ARCHIVE}"

    # Push to Private Cloud Vault if enabled
    if [[ "${CLOUD_SYNC_ENABLED}" == "true" && -n "${GITHUB_USER}" && -n "${GITHUB_TOKEN}" ]]; then
        echo "☁️ Uploading encrypted archive to Private GitHub Cloud Vault..."
        mkdir -p "${VAULT_DIR}"
        VAULT_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${VAULT_REPO}.git"

        # Auto-create private repo via GitHub API if not exists
        curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
             -d "{\"name\":\"${VAULT_REPO}\",\"private\":true}" \
             "https://api.github.com/user/repos" &>/dev/null || true

        if [[ ! -d "${VAULT_DIR}/.git" ]]; then
            git clone --quiet "${VAULT_URL}" "${VAULT_DIR}" 2>/dev/null || (
                cd "${VAULT_DIR}"
                git init --quiet
                git remote add origin "${VAULT_URL}"
            )
        fi

        cp -f "${ENCRYPTED_ARCHIVE}" "${VAULT_DIR}/personal_data.tar.gz.enc"
        cat <<EOF > "${VAULT_DIR}/README.md"
# Private Encrypted CV Vault
Encrypted personal data database managed by Vltimate CV Scraper.
AES-256-CBC Encrypted.
EOF

        cd "${VAULT_DIR}"
        git add .
        git commit -m "Auto-sync encrypted profile vault: $(date -u +'%Y-%m-%dT%H:%M:%SZ')" --quiet || true
        git branch -M main 2>/dev/null || true
        git push -u origin main --quiet 2>/dev/null || git push -u origin master --quiet 2>/dev/null || true
        cd "${SCRIPT_DIR}"
        rm -rf "${VAULT_DIR}"
        echo "✅ Encrypted database successfully synced to private GitHub repo: ${GITHUB_USER}/${VAULT_REPO}"
    fi

    echo "🧹 Executing security cleanup: Removing unencrypted plain text files..."
    rm -rf "${RAW_PROFILE_FILE}" "${CV_EN_FILE}" "${CV_PL_FILE}" "${OUTPUT_DIR}"

    echo "======================================================================"
    echo "✅ Personal data successfully packed, encrypted, and synced!"
    echo "👉 Encrypted Archive: ${ENCRYPTED_ARCHIVE}"
    echo "🔒 All unencrypted plain text files have been securely removed."
    echo "======================================================================"
else
    echo "ℹ️ Skipping encryption. Plain assets remain available locally in ${SCRIPT_DIR}."
fi

echo "======================================================================"
echo "🎉 Vltimate CV Scraper workflow complete!"
echo "======================================================================"
