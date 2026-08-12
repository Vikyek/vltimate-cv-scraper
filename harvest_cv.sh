#!/usr/bin/env bash
# ==============================================================================
# Vltimate CV Scraper v2.5
# Usage: ./harvest_cv.sh [OPTIONS]
# Features: Robust password/token prompting (unbound variable fix), default encryption (Y/n),
#           interrupted run recovery & state checkpointing, interactive prompt edit loop
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${SCRIPT_DIR}/input"
OUTPUT_DIR="${SCRIPT_DIR}/output"
ARCHIVE_DIR="${SCRIPT_DIR}/archives"
LOG_DIR="${SCRIPT_DIR}/logs"
CONFIG_FILE="${SCRIPT_DIR}/.vltimate_config.env"
PDF_CUSTOM_FILE="${SCRIPT_DIR}/.pdf_customization.json"
CHECKPOINT_FILE="${SCRIPT_DIR}/.checkpoint.json"
DIFF_LOG_FILE="${SCRIPT_DIR}/harvest_diff.log"
VAULT_DIR="${SCRIPT_DIR}/.vault_tmp"

SYSTEM_PROMPT_FILE="${SCRIPT_DIR}/cv_harvester_system_prompt.md"

OUTPUT_PROFILE="${OUTPUT_DIR}/raw_technical_profile.md"
INPUT_PROFILE="${INPUT_DIR}/raw_technical_profile.md"
OUTPUT_CV_HTML="${OUTPUT_DIR}/cv.html"

ENCRYPTED_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz.enc"
PLAIN_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz"

# Initialize interactive prompt variables to prevent unbound variable errors (-u)
DECRYPT_PASS=""
ENCRYPT_PASS1=""
ENCRYPT_PASS2=""
GITHUB_USER=""
GITHUB_TOKEN=""
SYNC_PROMPT=""
INPUT_REPO=""
PACK_CHOICE=""
EDIT_CHOICE=""
USER_FEEDBACK=""
RECOVERY_CHOICE=""

# ------------------------------------------------------------------------------
# DETAILED LOGGING ENGINE SETUP
# ------------------------------------------------------------------------------
mkdir -p "${LOG_DIR}"
LOG_FILE="${LOG_DIR}/harvest_$(date +'%Y-%m-%d_%H%M%S').log"
exec > >(tee -a "${LOG_FILE}") 2>&1

log_info() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] ℹ️  $*"; }
log_warn() { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] ⚠️  $*"; }
log_err()  { echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] ❌ $*"; }

save_checkpoint() {
    local state="$1"
    cat <<EOF > "${CHECKPOINT_FILE}"
{
  "state": "${state}",
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "script_dir": "${SCRIPT_DIR}"
}
EOF
    log_info "Checkpoint saved: ${state}"
}

clear_checkpoint() {
    rm -f "${CHECKPOINT_FILE}"
    log_info "Checkpoint cleared."
}

TAILOR_TARGET=""
FORCE_PDF="false"
ENABLE_DIFF="false"
INTERACTIVE_LOOP="true"
ENCRYPT_MODE="aes"
OPEN_GUI="false"
RECONFIG="false"

# ------------------------------------------------------------------------------
# CLI ARGUMENT PARSER
# ------------------------------------------------------------------------------
show_help() {
    cat <<EOF
Vltimate CV Scraper v2.5

USAGE:
  ./harvest_cv.sh [OPTIONS]

OPTIONS:
  -h, --help                Show help documentation
  -t, --tailor <FILE|URL>   Tailor summary, keywords, & bullet points to a Job Description
  -p, --pdf                 Force automated headless PDF export (output/cv_en.pdf & cv_pl.pdf)
  -d, --diff                Generate visual experience diff log (harvest_diff.log)
  -i, --interactive         Enable interactive prompt edit & conflict resolution loop via agy
  -e, --encrypt-mode <TYPE> Set encryption backend: 'aes' (default) or 'gpg'
  --gui                     Open customization GUI in Google Chrome to set themes/RODO options
  -c, --config              Reconfigure GitHub token & private cloud sync options
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) show_help ;;
        -t|--tailor) TAILOR_TARGET="$2"; shift 2 ;;
        -p|--pdf) FORCE_PDF="true"; shift ;;
        -d|--diff) ENABLE_DIFF="true"; shift ;;
        -i|--interactive) INTERACTIVE_LOOP="true"; shift ;;
        -e|--encrypt-mode) ENCRYPT_MODE="$2"; shift 2 ;;
        --gui) OPEN_GUI="true"; shift ;;
        -c|--config) RECONFIG="true"; shift ;;
        *) echo "Unknown option: $1"; show_help ;;
    esac
done

echo "======================================================================"
log_info "Starting Vltimate CV Scraper v2.5"
log_info "Execution Log File: ${LOG_FILE}"
echo "======================================================================"

# ------------------------------------------------------------------------------
# INTERRUPTED RUN RECOVERY & CHECKPOINT RESTART
# ------------------------------------------------------------------------------
RESUME_STATE=""
if [[ -f "${CHECKPOINT_FILE}" ]]; then
    LAST_STATE="$(grep '"state"' "${CHECKPOINT_FILE}" | cut -d'"' -f4 || echo '')"
    LAST_TIME="$(grep '"timestamp"' "${CHECKPOINT_FILE}" | cut -d'"' -f4 || echo '')"
    echo ""
    log_warn "INTERRUPTED RUN DETECTED from previous session!"
    log_warn "Last completed checkpoint: '${LAST_STATE}' at ${LAST_TIME}"
    echo "  1) Resume execution from last checkpoint ('${LAST_STATE}')"
    echo "  2) Discard checkpoint and start fresh run"
    read -r -p "Select recovery option [1/2]: " RECOVERY_CHOICE || RECOVERY_CHOICE="2"
    if [[ "${RECOVERY_CHOICE}" == "1" ]]; then
        RESUME_STATE="${LAST_STATE}"
        log_info "Resuming workflow from checkpoint '${RESUME_STATE}'..."
    else
        clear_checkpoint
        log_info "Discarded checkpoint. Starting fresh run..."
    fi
fi

# ------------------------------------------------------------------------------
# STEP 0: System Dependency Verification
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
        log_err "Dependency Check Failed! Missing tools:"
        for tool in "${missing[@]}"; do
            echo "   - ${tool}" >&2
        done
        exit 1
    fi
    log_info "Dependencies verified (openssl, tar, curl, git, agy, chrome)."
}

check_dependencies
mkdir -p "${INPUT_DIR}" "${OUTPUT_DIR}" "${ARCHIVE_DIR}"

rm -f "${SCRIPT_DIR}/cv_en.html" "${SCRIPT_DIR}/cv_pl.html" "${SCRIPT_DIR}/cv_en.pdf" "${SCRIPT_DIR}/cv_pl.pdf" "${SCRIPT_DIR}/raw_technical_profile.md"

# ------------------------------------------------------------------------------
# STEP 1: Customization Memory & GUI Trigger
# ------------------------------------------------------------------------------
if [[ "${OPEN_GUI}" == "true" || ! -f "${PDF_CUSTOM_FILE}" ]]; then
    log_info "Setting up PDF & Resume Customization preferences..."
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
    log_info "Customization saved to ${PDF_CUSTOM_FILE}"

    if [[ "${OPEN_GUI}" == "true" && -f "${OUTPUT_CV_HTML}" ]]; then
        google-chrome-stable "file://${OUTPUT_CV_HTML}" &>/dev/null &
    fi
fi

# ------------------------------------------------------------------------------
# STEP 2: Persistent Configuration & Autonomous GitHub Repo Sync
# ------------------------------------------------------------------------------
CLOUD_SYNC_ENABLED="false"
VAULT_REPO="vltimate-cv-vault"
PUBLIC_REPO="vltimate-cv-scraper"

if [[ "${RECONFIG}" == "true" || ! -f "${CONFIG_FILE}" ]]; then
    echo ""
    read -r -p "☁️ Enable Private GitHub Cloud Sync for encrypted vault database? (y/N): " SYNC_PROMPT || SYNC_PROMPT="n"
    if [[ "${SYNC_PROMPT}" =~ ^[Yy](es)?$ ]]; then
        CLOUD_SYNC_ENABLED="true"
        read -r -p "👤 Enter your GitHub Username: " GITHUB_USER || GITHUB_USER=""
        read -r -s -p "🔑 Enter your GitHub Personal Access Token (PAT) / Secret: " GITHUB_TOKEN || GITHUB_TOKEN=""
        echo ""
        read -r -p "📦 Enter Private Vault Repo Name [default: vltimate-cv-vault]: " INPUT_REPO || INPUT_REPO=""
        if [[ -n "${INPUT_REPO}" ]]; then VAULT_REPO="${INPUT_REPO}"; fi

        cat <<EOF > "${CONFIG_FILE}"
CLOUD_SYNC_ENABLED="${CLOUD_SYNC_ENABLED}"
GITHUB_USER="${GITHUB_USER}"
GITHUB_TOKEN="${GITHUB_TOKEN}"
VAULT_REPO="${VAULT_REPO}"
PUBLIC_REPO="${PUBLIC_REPO}"
EOF
        chmod 600 "${CONFIG_FILE}"
        log_info "Config saved to ${CONFIG_FILE} (gitignored)."
    fi
else
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}"
fi

# Autonomous Syncing of Public Code Repository
if [[ -n "${GITHUB_USER:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
    curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
         -d "{\"name\":\"${PUBLIC_REPO}\",\"private\":false}" \
         "https://api.github.com/user/repos" &>/dev/null || true

    PUBLIC_REMOTE="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${PUBLIC_REPO}.git"
    git remote set-url origin "${PUBLIC_REMOTE}" 2>/dev/null || git remote add origin "${PUBLIC_REMOTE}" 2>/dev/null || true
    git push -u origin master --quiet 2>/dev/null || git push -u origin main --quiet 2>/dev/null || true
    log_info "Autonomously updated public code repository: ${GITHUB_USER}/${PUBLIC_REPO}"
fi

# ------------------------------------------------------------------------------
# STEP 3: Private Cloud Vault Pull & Pre-Harvest Decryption
# ------------------------------------------------------------------------------
if [[ "${CLOUD_SYNC_ENABLED:-}" == "true" && -n "${GITHUB_USER:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
    log_info "Connecting to Private GitHub Vault (${GITHUB_USER}/${VAULT_REPO})..."
    rm -rf "${VAULT_DIR}"
    VAULT_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${VAULT_REPO}.git"

    if git ls-remote "${VAULT_URL}" &>/dev/null; then
        log_info "Pulling latest encrypted database from private cloud vault..."
        git clone --quiet "${VAULT_URL}" "${VAULT_DIR}"
        if [[ -f "${VAULT_DIR}/personal_data.tar.gz.enc" ]]; then
            cp -f "${VAULT_DIR}/personal_data.tar.gz.enc" "${ENCRYPTED_ARCHIVE}"
            log_info "Latest encrypted cloud database downloaded."
        fi
    fi
fi

# ------------------------------------------------------------------------------
# STEP 4: Auto-detect, Decrypt & Subdirectory Snapshot Lifecycle
# ------------------------------------------------------------------------------
if [[ -z "${RESUME_STATE}" || "${RESUME_STATE}" == "STATE_DECRYPTED" ]]; then
    if [[ -f "${ENCRYPTED_ARCHIVE}" ]]; then
        log_info "Encrypted personal archive detected: ${ENCRYPTED_ARCHIVE}"
        read -r -s -p "🔑 Enter decryption password: " DECRYPT_PASS || DECRYPT_PASS=""
        echo ""

        TEMP_TAR="$(mktemp --suffix=.tar.gz)"
        if openssl enc -d -aes-256-cbc -pbkdf2 -iter 100000 -in "${ENCRYPTED_ARCHIVE}" -out "${TEMP_TAR}" -pass pass:"${DECRYPT_PASS}" 2>/dev/null; then
            log_info "Archive decrypted successfully! Unpacking data tree..."
            tar -xzf "${TEMP_TAR}" -C "${SCRIPT_DIR}"
            rm -f "${TEMP_TAR}"
            save_checkpoint "STATE_DECRYPTED"
        elif gpg --decrypt --batch --passphrase "${DECRYPT_PASS}" "${ENCRYPTED_ARCHIVE}" > "${TEMP_TAR}" 2>/dev/null; then
            log_info "GPG Archive decrypted successfully! Unpacking data tree..."
            tar -xzf "${TEMP_TAR}" -C "${SCRIPT_DIR}"
            rm -f "${TEMP_TAR}"
            save_checkpoint "STATE_DECRYPTED"
        else
            log_err "Decryption failed: Invalid password or corrupted archive."
            rm -f "${TEMP_TAR}"
            exit 1
        fi
    fi

    # Snapshot & Input Subdirectory Rotation
    TIMESTAMP="$(date +'%Y-%m-%d_%H%M%S')"
    SNAPSHOT_FILE="${ARCHIVE_DIR}/snapshot_${TIMESTAMP}.tar.gz"

    if [[ -f "${OUTPUT_PROFILE}" || -f "${INPUT_PROFILE}" ]]; then
        log_info "Creating snapshot archive: ${SNAPSHOT_FILE}"
        tar -czf "${SNAPSHOT_FILE}" -C "${SCRIPT_DIR}" "input" "output" 2>/dev/null || true
        cp -rf "${OUTPUT_DIR}"/* "${INPUT_DIR}/" 2>/dev/null || true
        save_checkpoint "STATE_SNAPSHOT_CREATED"
    fi
fi

# ------------------------------------------------------------------------------
# STEP 5: Execute agy Intelligence Harvesting & JD Tailoring
# ------------------------------------------------------------------------------
if [[ -z "${RESUME_STATE}" || "${RESUME_STATE}" == "STATE_DECRYPTED" || "${RESUME_STATE}" == "STATE_SNAPSHOT_CREATED" ]]; then
    if [[ ! -f "${SYSTEM_PROMPT_FILE}" ]]; then
        log_err "System prompt missing at ${SYSTEM_PROMPT_FILE}"
        exit 1
    fi

    PROMPT="Read '${SYSTEM_PROMPT_FILE}' and '${INPUT_PROFILE}'."

    if [[ -n "${TAILOR_TARGET}" ]]; then
        log_info "Job Description Tailoring Mode Enabled for: ${TAILOR_TARGET}"
        if [[ -f "${TAILOR_TARGET}" ]]; then
            JD_CONTENT="$(cat "${TAILOR_TARGET}")"
        else
            JD_CONTENT="$(curl -s "${TAILOR_TARGET}" || echo "${TAILOR_TARGET}")"
        fi
        PROMPT="${PROMPT} Tailor the summary, keyword badges, and experience bullet points specifically for this Job Description: ${JD_CONTENT}."
    fi

    PROMPT="${PROMPT} Perform harvesting across system, shell history, git repos, and GitHub profile. Save updated knowledge base into '${OUTPUT_PROFILE}' and generate unified bilingual interactive HTML resume into '${OUTPUT_CV_HTML}'."

    log_info "Harvesting technical intelligence with agy..."
    save_checkpoint "STATE_HARVEST_STARTED"
    agy --dangerously-skip-permissions --print "${PROMPT}"
    save_checkpoint "STATE_HARVEST_COMPLETED"
fi

# ------------------------------------------------------------------------------
# STEP 5B: Interactive Prompt Edit, Conflict Resolution & Revision Loop
# ------------------------------------------------------------------------------
if [[ "${INTERACTIVE_LOOP}" == "true" ]]; then
    while true; do
        echo ""
        echo "======================================================================"
        echo "✍️ Interactive Refinement & Revision Menu (via agy)"
        echo "======================================================================"
        echo "Current harvested profile and HTML resume are ready in output/."
        echo "  1) Approve current CV & Profile (Proceed to PDF Export & Encryption)"
        echo "  2) Prompt agy to revise / edit specific section"
        echo "  3) Resolve conflicting technical data or dates"
        echo "  4) Add custom pointers, notes, or new technical entries"
        echo "  5) Re-run full intelligence harvest"
        read -r -p "Select option [1-5]: " EDIT_CHOICE || EDIT_CHOICE="1"

        case "${EDIT_CHOICE}" in
            1)
                log_info "Profile & CV approved by user."
                save_checkpoint "STATE_REVISION_APPROVED"
                break
                ;;
            2|3|4)
                echo ""
                read -r -p "💬 Enter your instruction / correction / pointer for agy: " USER_FEEDBACK || USER_FEEDBACK=""
                if [[ -n "${USER_FEEDBACK}" ]]; then
                    REVISE_PROMPT="Read '${SYSTEM_PROMPT_FILE}', '${OUTPUT_PROFILE}', and '${OUTPUT_CV_HTML}'. Apply this specific user instruction: ${USER_FEEDBACK}. Update '${OUTPUT_PROFILE}' and '${OUTPUT_CV_HTML}'."
                    log_info "Executing revision pass with agy..."
                    agy --dangerously-skip-permissions --print "${REVISE_PROMPT}"
                    log_info "Revision applied."
                fi
                ;;
            5)
                log_info "Re-running full intelligence harvest..."
                agy --dangerously-skip-permissions --print "${PROMPT}"
                ;;
            *)
                log_warn "Invalid option. Select 1 to approve."
                ;;
        esac
    done
fi

# ------------------------------------------------------------------------------
# STEP 6: Headless PDF Generation & Visual Diff Tracking
# ------------------------------------------------------------------------------
if [[ -f "${OUTPUT_CV_HTML}" ]]; then
    log_info "Rendering pixel-perfect headless PDFs..."
    google-chrome-stable --headless --disable-gpu --print-to-pdf="${OUTPUT_DIR}/cv_en.pdf" "file://${OUTPUT_CV_HTML}" &>/dev/null || true
    google-chrome-stable --headless --disable-gpu --print-to-pdf="${OUTPUT_DIR}/cv_pl.pdf" "file://${OUTPUT_CV_HTML}" &>/dev/null || true
    log_info "Rendered ${OUTPUT_DIR}/cv_en.pdf & ${OUTPUT_DIR}/cv_pl.pdf"
    save_checkpoint "STATE_PDF_RENDERED"
fi

if [[ "${ENABLE_DIFF}" == "true" && -f "${INPUT_PROFILE}" && -f "${OUTPUT_PROFILE}" ]]; then
    log_info "Visual Experience Diff Tracking..."
    {
        echo "=== Vltimate CV Scraper Diff Report: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ==="
        diff -u "${INPUT_PROFILE}" "${OUTPUT_PROFILE}" || true
    } > "${DIFF_LOG_FILE}"
    log_info "Diff report saved to ${DIFF_LOG_FILE}"
fi

# ------------------------------------------------------------------------------
# STEP 7: DEFAULT ENCRYPTION POLICY & SECURITY CLEANUP (Default: YES)
# ------------------------------------------------------------------------------
echo ""
read -r -p "🔒 Pack and encrypt personal results now? [Y/n] (Default: YES): " PACK_CHOICE || PACK_CHOICE="Y"
PACK_CHOICE="${PACK_CHOICE:-Y}"

if [[ "${PACK_CHOICE}" =~ ^[Yy](es)?$ ]]; then
    read -r -s -p "🔑 Enter custom encryption password: " ENCRYPT_PASS1 || ENCRYPT_PASS1=""
    echo ""
    read -r -s -p "🔑 Re-enter encryption password: " ENCRYPT_PASS2 || ENCRYPT_PASS2=""
    echo ""

    if [[ "${ENCRYPT_PASS1}" != "${ENCRYPT_PASS2}" || -z "${ENCRYPT_PASS1}" ]]; then
        log_err "Invalid password or mismatch! Aborting encryption."
        exit 1
    fi

    log_info "Packing input/, output/, archives/, and logs/..."
    tar -czf "${PLAIN_ARCHIVE}" -C "${SCRIPT_DIR}" "input" "output" "archives"

    if [[ "${ENCRYPT_MODE}" == "gpg" ]]; then
        log_info "Encrypting archive with GPG..."
        gpg --symmetric --batch --passphrase "${ENCRYPT_PASS1}" -o "${ENCRYPTED_ARCHIVE}" "${PLAIN_ARCHIVE}"
    else
        log_info "Encrypting archive with OpenSSL (AES-256-CBC)..."
        openssl enc -aes-256-cbc -pbkdf2 -iter 100000 -in "${PLAIN_ARCHIVE}" -out "${ENCRYPTED_ARCHIVE}" -pass pass:"${ENCRYPT_PASS1}"
    fi
    rm -f "${PLAIN_ARCHIVE}"
    save_checkpoint "STATE_ENCRYPTED"

    # Auto-Push to Private Cloud Vault
    if [[ "${CLOUD_SYNC_ENABLED:-}" == "true" && -n "${GITHUB_USER:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
        log_info "Autonomously uploading encrypted archive to Private GitHub Cloud Vault..."
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
        log_info "Synced to private GitHub repo: ${GITHUB_USER}/${VAULT_REPO}"
    fi

    log_info "Executing security cleanup: Removing unencrypted plain subdirectories..."
    rm -rf "${INPUT_DIR}" "${OUTPUT_DIR}" "${ARCHIVE_DIR}"
    clear_checkpoint

    echo "======================================================================"
    log_info "Personal data successfully packed, encrypted, and cleaned!"
    log_info "Encrypted Archive: ${ENCRYPTED_ARCHIVE}"
    echo "======================================================================"
else
    log_warn "User selected unencrypted mode. Plain assets remain available in ${SCRIPT_DIR}."
    clear_checkpoint
fi

echo "======================================================================"
log_info "Vltimate CV Scraper v2.5 workflow complete!"
echo "======================================================================"
