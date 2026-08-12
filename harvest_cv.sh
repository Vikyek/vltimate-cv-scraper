#!/usr/bin/env bash
# ==============================================================================
# Vltimate CV Scraper v2.1
# Usage: ./harvest_cv.sh [OPTIONS]
# Options:
#   -h, --help                Show help documentation
#   -t, --tailor <FILE|URL>   Tailor CV specifically to a job description file/URL
#   -p, --pdf                 Force automated headless PDF export (cv_en.pdf / cv_pl.pdf)
#   -d, --diff                Generate visual experience diff log (harvest_diff.log)
#   -e, --encrypt-mode <TYPE> Encryption mode: aes (OpenSSL, default) or gpg
#   --gui                     Open customization GUI in Google Chrome to set themes/RODO options
#   -c, --config              Reconfigure GitHub token & private cloud sync options
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${SCRIPT_DIR}/input"
OUTPUT_DIR="${SCRIPT_DIR}/output"
ARCHIVE_DIR="${SCRIPT_DIR}/archives"
CONFIG_FILE="${SCRIPT_DIR}/.vltimate_config.env"
PDF_CUSTOM_FILE="${SCRIPT_DIR}/.pdf_customization.json"
DIFF_LOG_FILE="${SCRIPT_DIR}/harvest_diff.log"
VAULT_DIR="${SCRIPT_DIR}/.vault_tmp"

SYSTEM_PROMPT_FILE="${SCRIPT_DIR}/cv_harvester_system_prompt.md"
TEMPLATE_FILE="${SCRIPT_DIR}/cv_template.html"

# Assets paths inside input/output subdirectories
OUTPUT_PROFILE="${OUTPUT_DIR}/raw_technical_profile.md"
INPUT_PROFILE="${INPUT_DIR}/raw_technical_profile.md"
OUTPUT_CV_HTML="${OUTPUT_DIR}/cv.html"

ENCRYPTED_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz.enc"
PLAIN_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz"

TAILOR_TARGET=""
FORCE_PDF="false"
ENABLE_DIFF="false"
ENCRYPT_MODE="aes"
OPEN_GUI="false"
RECONFIG="false"

# ------------------------------------------------------------------------------
# CLI ARGUMENT PARSER & HELP FUNCTION
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Vltimate CV Scraper v2.1 - Technical Intelligence Harvester & ATS Engine

USAGE:
  ./harvest_cv.sh [OPTIONS]

OPTIONS:
  -h, --help                Show this help message and exit
  -t, --tailor <FILE|URL>   Tailor summary, keywords, & bullet points to a Job Description
  -p, --pdf                 Force automated headless PDF export (cv_en.pdf / cv_pl.pdf)
  -d, --diff                Generate visual experience diff log (harvest_diff.log)
  -e, --encrypt-mode <TYPE> Set encryption backend: 'aes' (OpenSSL AES-256) or 'gpg'
  --gui                     Open customization GUI in Google Chrome to set themes/RODO options
  -c, --config              Reconfigure GitHub token & private cloud sync options

EXAMPLES:
  ./harvest_cv.sh --pdf --diff
  ./harvest_cv.sh --tailor ./job_offer.txt
  ./harvest_cv.sh --encrypt-mode gpg
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) show_help ;;
        -t|--tailor) TAILOR_TARGET="$2"; shift 2 ;;
        -p|--pdf) FORCE_PDF="true"; shift ;;
        -d|--diff) ENABLE_DIFF="true"; shift ;;
        -e|--encrypt-mode) ENCRYPT_MODE="$2"; shift 2 ;;
        --gui) OPEN_GUI="true"; shift ;;
        -c|--config) RECONFIG="true"; shift ;;
        *) echo "Unknown option: $1"; show_help ;;
    esac
done

echo "======================================================================"
echo "🚀 Vltimate CV Scraper v2.1"
echo "Working Directory: ${SCRIPT_DIR}"
echo "======================================================================"

# ------------------------------------------------------------------------------
# STEP 0: System Dependency Verification & Subdirectory Tree Init
# ------------------------------------------------------------------------------
check_dependencies() {
    local missing=()
    local required_tools=("openssl" "tar" "curl" "git" "agy" "google-chrome-stable")

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
        echo "Please install missing dependencies:" >&2
        echo "   Arch Linux:  paru -S openssl tar curl git google-chrome" >&2
        echo "   Antigravity: npm install -g @google/antigravity-cli" >&2
        echo "======================================================================" >&2
        exit 1
    fi
    echo "✅ System dependencies verified (openssl, tar, curl, git, agy, chrome)."
}

check_dependencies
mkdir -p "${INPUT_DIR}" "${OUTPUT_DIR}" "${ARCHIVE_DIR}"

# Remove any legacy standalone top-level html/pdf files to keep directory clean
rm -f "${SCRIPT_DIR}/cv_en.html" "${SCRIPT_DIR}/cv_pl.html" "${SCRIPT_DIR}/cv_en.pdf" "${SCRIPT_DIR}/cv_pl.pdf" "${SCRIPT_DIR}/raw_technical_profile.md"

# ------------------------------------------------------------------------------
# STEP 1: Customization Memory & GUI Trigger
# ------------------------------------------------------------------------------
if [[ "${OPEN_GUI}" == "true" || ! -f "${PDF_CUSTOM_FILE}" ]]; then
    echo "🎨 Setting up PDF & Resume Customization preferences..."
    cat <<EOF > "${PDF_CUSTOM_FILE}"
{
  "theme": "theme-blue",
  "language": "en",
  "rodo": "universal",
  "paperSize": "A4",
  "margin": "none",
  "backgroundGraphics": true
}
EOF
    echo "💾 Saved customization preferences to ${PDF_CUSTOM_FILE}"

    if [[ "${OPEN_GUI}" == "true" && -f "${OUTPUT_CV_HTML}" ]]; then
        echo "🌐 Opening customization GUI in browser..."
        google-chrome-stable "file://${OUTPUT_CV_HTML}" &>/dev/null &
    fi
fi

# ------------------------------------------------------------------------------
# STEP 2: Persistent Configuration & Autonomous GitHub Vault Repo Creation
# ------------------------------------------------------------------------------
CLOUD_SYNC_ENABLED="false"
GITHUB_USER=""
GITHUB_TOKEN=""
VAULT_REPO="vltimate-cv-vault"
PUBLIC_REPO="vltimate-cv-scraper"

if [[ "${RECONFIG}" == "true" || ! -f "${CONFIG_FILE}" ]]; then
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

        cat <<EOF > "${CONFIG_FILE}"
CLOUD_SYNC_ENABLED="${CLOUD_SYNC_ENABLED}"
GITHUB_USER="${GITHUB_USER}"
GITHUB_TOKEN="${GITHUB_TOKEN}"
VAULT_REPO="${VAULT_REPO}"
PUBLIC_REPO="${PUBLIC_REPO}"
EOF
        chmod 600 "${CONFIG_FILE}"
        echo "💾 Config saved to ${CONFIG_FILE} (gitignored)."
    fi
else
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}"
fi

# Autonomous Creation & Syncing of Public Code Repository (Never asking user!)
if [[ -n "${GITHUB_USER}" && -n "${GITHUB_TOKEN}" ]]; then
    curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
         -d "{\"name\":\"${PUBLIC_REPO}\",\"private\":false}" \
         "https://api.github.com/user/repos" &>/dev/null || true

    PUBLIC_REMOTE="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${PUBLIC_REPO}.git"
    git remote set-url origin "${PUBLIC_REMOTE}" 2>/dev/null || git remote add origin "${PUBLIC_REMOTE}" 2>/dev/null || true
    git push -u origin master --quiet 2>/dev/null || git push -u origin main --quiet 2>/dev/null || true
    echo "⚡ Autonomously updated public code repository: ${GITHUB_USER}/${PUBLIC_REPO}"
fi

# ------------------------------------------------------------------------------
# STEP 3: Private Cloud Vault Pull & Pre-Harvest Decryption
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
            echo "✅ Latest encrypted cloud database downloaded."
        fi
    fi
fi

# ------------------------------------------------------------------------------
# STEP 4: Auto-detect, Decrypt & Subdirectory Snapshot Lifecycle
# ------------------------------------------------------------------------------
if [[ -f "${ENCRYPTED_ARCHIVE}" ]]; then
    echo "🔐 Encrypted personal archive detected: ${ENCRYPTED_ARCHIVE}"
    echo -n "🔑 Enter decryption password: "
    read -sp DECRYPT_PASS
    echo ""

    TEMP_TAR="$(mktemp --suffix=.tar.gz)"
    if openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in "${ENCRYPTED_ARCHIVE}" -out "${TEMP_TAR}" -pass pass:"${DECRYPT_PASS}" 2>/dev/null; then
        echo "🔓 Archive decrypted successfully! Unpacking data tree..."
        tar -xzf "${TEMP_TAR}" -C "${SCRIPT_DIR}"
        rm -f "${TEMP_TAR}"
    elif gpg --decrypt --batch --passphrase "${DECRYPT_PASS}" "${ENCRYPTED_ARCHIVE}" > "${TEMP_TAR}" 2>/dev/null; then
        echo "🔓 GPG Archive decrypted successfully! Unpacking data tree..."
        tar -xzf "${TEMP_TAR}" -C "${SCRIPT_DIR}"
        rm -f "${TEMP_TAR}"
    else
        echo "❌ Decryption failed: Invalid password or corrupted archive." >&2
        rm -f "${TEMP_TAR}"
        exit 1
    fi
elif [[ -f "${PLAIN_ARCHIVE}" ]]; then
    echo "📦 Packed archive detected. Unpacking..."
    tar -xzf "${PLAIN_ARCHIVE}" -C "${SCRIPT_DIR}"
fi

# Snapshot & Input Subdirectory Rotation
TIMESTAMP="$(date +'%Y-%m-%d_%H%M%S')"
SNAPSHOT_FILE="${ARCHIVE_DIR}/snapshot_${TIMESTAMP}.tar.gz"

if [[ -f "${OUTPUT_PROFILE}" || -f "${INPUT_PROFILE}" ]]; then
    echo "📦 Creating timestamped snapshot archive: ${SNAPSHOT_FILE}"
    tar -czf "${SNAPSHOT_FILE}" -C "${SCRIPT_DIR}" "input" "output" 2>/dev/null || true
    echo "🔄 Rotating output data into input/ subdirectory for baseline building..."
    cp -rf "${OUTPUT_DIR}"/* "${INPUT_DIR}/" 2>/dev/null || true
fi

# ------------------------------------------------------------------------------
# STEP 5: Execute agy Intelligence Harvesting & JD Tailoring
# ------------------------------------------------------------------------------
if [[ ! -f "${SYSTEM_PROMPT_FILE}" ]]; then
    echo "Error: System prompt missing at ${SYSTEM_PROMPT_FILE}" >&2
    exit 1
fi

PROMPT="Read '${SYSTEM_PROMPT_FILE}' and '${INPUT_PROFILE}'."

if [[ -n "${TAILOR_TARGET}" ]]; then
    echo "🎯 Job Description Tailoring Mode Enabled for: ${TAILOR_TARGET}"
    if [[ -f "${TAILOR_TARGET}" ]]; then
        JD_CONTENT="$(cat "${TAILOR_TARGET}")"
    else
        JD_CONTENT="$(curl -s "${TAILOR_TARGET}" || echo "${TAILOR_TARGET}")"
    fi
    PROMPT="${PROMPT} Tailor the summary, keyword badges, and experience bullet points specifically for this Job Description: ${JD_CONTENT}."
fi

PROMPT="${PROMPT} Perform harvesting across system, shell history, git repos, and GitHub profile. Save updated knowledge base into '${OUTPUT_PROFILE}' and generate unified bilingual interactive HTML resume into '${OUTPUT_CV_HTML}' (containing both English and Polish pages, theme picker, and RODO selector)."

echo "======================================================================"
echo "⚡ Harvesting technical intelligence with agy..."
echo "======================================================================"
agy --dangerously-skip-permissions --print "${PROMPT}"

# ------------------------------------------------------------------------------
# STEP 6: Headless PDF Generation & Visual Diff Tracking
# ------------------------------------------------------------------------------
if [[ -f "${OUTPUT_CV_HTML}" ]]; then
    echo "======================================================================"
    echo "🖨️ Rendering pixel-perfect headless PDFs..."
    echo "======================================================================"
    google-chrome-stable --headless --disable-gpu --print-to-pdf="${OUTPUT_DIR}/cv_en.pdf" "file://${OUTPUT_CV_HTML}" &>/dev/null || true
    google-chrome-stable --headless --disable-gpu --print-to-pdf="${OUTPUT_DIR}/cv_pl.pdf" "file://${OUTPUT_CV_HTML}" &>/dev/null || true
    echo "✅ Rendered ${OUTPUT_DIR}/cv_en.pdf & ${OUTPUT_DIR}/cv_pl.pdf"
fi

if [[ "${ENABLE_DIFF}" == "true" && -f "${INPUT_PROFILE}" && -f "${OUTPUT_PROFILE}" ]]; then
    echo "======================================================================"
    echo "📊 Visual Experience Diff Tracking..."
    echo "======================================================================"
    {
        echo "=== Vltimate CV Scraper Diff Report: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ==="
        diff -u "${INPUT_PROFILE}" "${OUTPUT_PROFILE}" || true
    } > "${DIFF_LOG_FILE}"
    echo "✅ Diff report saved to ${DIFF_LOG_FILE}"
fi

# ------------------------------------------------------------------------------
# STEP 7: Interactive Prompt for Packing, Encryption & Cloud Sync
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

    if [[ "${ENCRYPT_PASS1}" != "${ENCRYPT_PASS2}" || -z "${ENCRYPT_PASS1}" ]]; then
        echo "❌ Invalid password or mismatch! Aborting encryption." >&2
        exit 1
    fi

    echo "📦 Packing input/, output/, and archives/ subdirectories..."
    tar -czf "${PLAIN_ARCHIVE}" -C "${SCRIPT_DIR}" "input" "output" "archives"

    if [[ "${ENCRYPT_MODE}" == "gpg" ]]; then
        echo "🔒 Encrypting archive with GPG..."
        gpg --symmetric --batch --passphrase "${ENCRYPT_PASS1}" -o "${ENCRYPTED_ARCHIVE}" "${PLAIN_ARCHIVE}"
    else
        echo "🔒 Encrypting archive with OpenSSL (AES-256-CBC with PBKDF2)..."
        openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -in "${PLAIN_ARCHIVE}" -out "${ENCRYPTED_ARCHIVE}" -pass pass:"${ENCRYPT_PASS1}"
    fi
    rm -f "${PLAIN_ARCHIVE}"

    # Auto-Push to Private Cloud Vault
    if [[ "${CLOUD_SYNC_ENABLED}" == "true" && -n "${GITHUB_USER}" && -n "${GITHUB_TOKEN}" ]]; then
        echo "☁️ Autonomously uploading encrypted archive to Private GitHub Cloud Vault..."
        mkdir -p "${VAULT_DIR}"
        VAULT_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${VAULT_REPO}.git"

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
Encrypted personal database managed by Vltimate CV Scraper.
EOF

        cd "${VAULT_DIR}"
        git add .
        git commit -m "Auto-sync vault: $(date -u +'%Y-%m-%dT%H:%M:%SZ')" --quiet || true
        git branch -M main 2>/dev/null || true
        git push -u origin main --quiet 2>/dev/null || git push -u origin master --quiet 2>/dev/null || true
        cd "${SCRIPT_DIR}"
        rm -rf "${VAULT_DIR}"
        echo "✅ Synced to private GitHub repo: ${GITHUB_USER}/${VAULT_REPO}"
    fi

    echo "🧹 Executing security cleanup: Removing unencrypted plain subdirectories..."
    rm -rf "${INPUT_DIR}" "${OUTPUT_DIR}" "${ARCHIVE_DIR}"

    echo "======================================================================"
    echo "✅ Personal data successfully packed, encrypted, and cleaned!"
    echo "👉 Archive: ${ENCRYPTED_ARCHIVE}"
    echo "======================================================================"
else
    echo "ℹ️ Skipping encryption. Plain assets remain available in ${SCRIPT_DIR}."
fi

echo "======================================================================"
echo "🎉 Vltimate CV Scraper v2.1 workflow complete!"
echo "======================================================================"
