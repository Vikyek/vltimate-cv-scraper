#!/usr/bin/env bash
# ==============================================================================
# Vltimate CV Scraper v3.5 (Production Master)
# Usage: ./harvest_cv.sh [OPTIONS]
# Changes in v3.5:
#   - Universal Unicode Glyphs: Replaced multi-byte color emojis with rock-solid single-width glyphs (✦, ⚡, ◈, ◆, ✔, ✘, ▲, ℹ)
#   - Automatic Customization Pick-Up: Auto-detects & moves downloaded GUI configs from ~/Downloads/
#   - Dynamic Source Summary: Compact, glowing summary instead of repetitive lines
#   - Log Path & Flag: Log path hidden from startup; accessible via -l / --log flag
#   - User-Friendly Interrupted Run: Simplified resume prompt without technical checkpoint jargon
#   - Silent Snapshot Logging: Snapshot archive creation hidden from stdout unless verbose (-v)
#   - Magical Aesthetics: Enhanced TrueColor ANSI gradients, starry glyphs, and box art
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${SCRIPT_DIR}/input"
OUTPUT_DIR="${SCRIPT_DIR}/output"
ARCHIVE_DIR="${SCRIPT_DIR}/archives"
LOCAL_PREVIEW_DIR="${SCRIPT_DIR}/local_preview"
LOG_DIR="${SCRIPT_DIR}/logs"
CONFIG_DIR="${SCRIPT_DIR}/config"
CONFIG_FILE="${CONFIG_DIR}/vltimate_config.env"
PDF_CUSTOM_FILE="${CONFIG_DIR}/pdf_customization.json"
CHECKPOINT_FILE="${CONFIG_DIR}/checkpoint.json"
DIFF_LOG_FILE="${SCRIPT_DIR}/harvest_diff.log"
AUDIT_FILE="${CONFIG_DIR}/conflict_audit.json"
VAULT_DIR="${SCRIPT_DIR}/.vault_tmp"

SYSTEM_PROMPT_FILE="${SCRIPT_DIR}/cv_harvester_system_prompt.md"
TEMPLATE_FILE="${SCRIPT_DIR}/cv_template.html"

OUTPUT_PROFILE="${OUTPUT_DIR}/raw_technical_profile.md"
INPUT_PROFILE="${INPUT_DIR}/raw_technical_profile.md"
OUTPUT_CV_HTML="${OUTPUT_DIR}/cv.html"

ENCRYPTED_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz.enc"
PLAIN_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz"

# ------------------------------------------------------------------------------
# TRUECOLOR ANSI STYLING PALETTE (Cyberpunk / Trans HSL)
# ------------------------------------------------------------------------------
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_CYAN='\033[38;2;91;206;250m'     # Trans Cyan #5BCEFA
C_PINK='\033[38;2;245;169;184m'    # Trans Pink #F5A9B8
C_WHITE='\033[38;2;255;255;255m'   # Pure White #FFFFFF
C_MAGENTA='\033[38;2;255;102;204m' # Neon Magenta #FF66CC
C_VIOLET='\033[38;2;170;85;255m'   # Neon Violet #AA55FF
C_GREEN='\033[38;2;80;250;123m'    # Mint Green #50FA7B
C_GOLD='\033[38;2;255;184;108m'    # Warm Gold #FFB86C
C_RED='\033[38;2;255;85;85m'       # Bright Red #FF5555

cleanup_secrets() {
    unset GITHUB_TOKEN DECRYPT_PASS ENCRYPT_PASS ENCRYPT_PASS1 ENCRYPT_PASS2 GH_TOKEN VAULT_PAT 2>/dev/null || true
}
trap cleanup_secrets EXIT INT TERM

ENCRYPT_PASS2=""
GITHUB_USER="${GITHUB_USER:-Vikyek}"
GITHUB_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
SYNC_PROMPT=""
INPUT_REPO=""
PACK_CHOICE=""
EDIT_CHOICE=""
USER_FEEDBACK=""
RECOVERY_CHOICE=""
RESOLUTION_INPUT=""
OPEN_GUI_PROMPT=""
METHOD_CHOICE=""

VERBOSE="false"
TAILOR_TARGET=""
FORCE_PDF="false"
ENABLE_DIFF="false"
INTERACTIVE_LOOP="true"
ENCRYPT_MODE="aes"
OPEN_GUI="false"
RECONFIG="false"
ONLY_VIEW="false"
VIEW_DB="false"
VIEW_LOG="false"
MANUAL_SOURCES=()

# ------------------------------------------------------------------------------
# LOGGING ENGINE & AESTHETIC CONSOLE OUTPUT (LOG SECRET REDACTION)
# ------------------------------------------------------------------------------
mkdir -p "${LOG_DIR}" "${CONFIG_DIR}"
LOG_FILE="${LOG_DIR}/harvest_$(date +'%Y-%m-%d_%H%M%S').log"

print_banner() {
    echo -e "${C_CYAN}┌────────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_CYAN}│  ${C_BOLD}${C_MAGENTA}✦ VLTIMATE CV SCRAPER v3.5${C_RESET}${C_CYAN} — Technical Intelligence & ATS Engine │${C_RESET}"
    echo -e "${C_CYAN}│  ${C_PINK}Autonomous Scraping • Multi-Shell Mining • Cross-Site Discovery${C_RESET}${C_CYAN}      │${C_RESET}"
    echo -e "${C_CYAN}└────────────────────────────────────────────────────────────────────────┘${C_RESET}"
}

sanitize_log_msg() {
    local msg="$*"
    msg="$(echo "${msg}" | sed -E 's/(github_pat_[A-Za-z0-9_]+|ghp_[A-Za-z0-9_]+)/[REDACTED_PAT]/g')"
    echo "${msg}"
}

log_info() {
    local timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    local clean_msg="$(sanitize_log_msg "$*")"
    echo "[${timestamp}] ℹ ${clean_msg}" >> "${LOG_FILE}"
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${C_DIM}[${timestamp}]${C_RESET} ${C_CYAN}ℹ ${clean_msg}${C_RESET}"
    else
        echo -e "${C_CYAN}ℹ ${clean_msg}${C_RESET}"
    fi
}

log_warn() {
    local timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    local clean_msg="$(sanitize_log_msg "$*")"
    echo "[${timestamp}] ▲ ${clean_msg}" >> "${LOG_FILE}"
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${C_DIM}[${timestamp}]${C_RESET} ${C_GOLD}▲ ${clean_msg}${C_RESET}"
    else
        echo -e "${C_GOLD}▲ ${clean_msg}${C_RESET}"
    fi
}

log_err() {
    local timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    local clean_msg="$(sanitize_log_msg "$*")"
    echo "[${timestamp}] ✘ ${clean_msg}" >> "${LOG_FILE}"
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${C_DIM}[${timestamp}]${C_RESET} ${C_RED}✘ ${clean_msg}${C_RESET}"
    else
        echo -e "${C_RED}✘ ${clean_msg}${C_RESET}"
    fi
}

save_checkpoint() {
    local state="$1"
    cat <<EOF > "${CHECKPOINT_FILE}"
{
  "state": "${state}",
  "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
  "script_dir": "${SCRIPT_DIR}"
}
EOF
    local timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo "[${timestamp}] ℹ Checkpoint saved: '${state}'" >> "${LOG_FILE}"
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${C_DIM}[${timestamp}]${C_RESET} ${C_VIOLET}◈ Checkpoint saved: '${state}'${C_RESET}"
    fi
}

clear_checkpoint() {
    rm -f "${CHECKPOINT_FILE}" "${AUDIT_FILE}"
    local timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    echo "[${timestamp}] ℹ Checkpoint cleared." >> "${LOG_FILE}"
    if [[ "${VERBOSE}" == "true" ]]; then
        echo -e "${C_DIM}[${timestamp}]${C_RESET} ${C_VIOLET}◈ Checkpoint cleared.${C_RESET}"
    fi
}

# ------------------------------------------------------------------------------
# AUTOMATIC DOWNLOADED CUSTOMIZATION PICK-UP & AUTO-MOVE (NO TRASH FILES)
# ------------------------------------------------------------------------------
search_and_move_customization() {
    local search_path="$1"
    local candidate=""

    # Expand tilde ~ if passed
    search_path="${search_path/#\~/$HOME}"

    if [[ -f "${search_path}" ]]; then
        candidate="${search_path}"
    elif [[ -d "${search_path}" ]]; then
        candidate="$(find "${search_path}" -maxdepth 2 \( -name "pdf_customization*.json" -o -name ".pdf_customization*.json" \) 2>/dev/null | head -n 1 || echo '')"
    fi

    if [[ -n "${candidate}" && -f "${candidate}" ]]; then
        mv -f "${candidate}" "${PDF_CUSTOM_FILE}"
        chmod 600 "${PDF_CUSTOM_FILE}"
        log_info "✦ Automatically moved customization config: '${candidate}' -> './config/pdf_customization.json'"
        return 0
    fi
    return 1
}

pickup_downloaded_customization() {
    if search_and_move_customization "${HOME}/Downloads" || \
       search_and_move_customization "${SCRIPT_DIR}" || \
       search_and_move_customization "${HOME}/Desktop"; then
        return 0
    fi
    return 1
}

# ------------------------------------------------------------------------------
# MASKED SECRET INPUT (shows * for each character)
# ------------------------------------------------------------------------------
read_secret() {
    local prompt="$1"
    local input=""
    local char=""
    
    tput civis >&2 2>/dev/null || true
    printf "%b" "${C_MAGENTA}${prompt}${C_RESET}" >&2
    
    while IFS= read -r -s -n1 char; do
        if [[ -z "$char" ]]; then
            break
        elif [[ "$char" == $'\x7f' || "$char" == $'\b' ]]; then
            if [[ -n "$input" ]]; then
                input="${input%?}"
                printf "\b \b" >&2
            fi
        else
            input+="$char"
            printf "${C_PINK}*${C_RESET}" >&2
        fi
    done
    
    tput cnorm >&2 2>/dev/null || true
    echo "" >&2
    echo "$input"
}

# ------------------------------------------------------------------------------
# ANIMATED MULTICOLOR CLI SPINNER (crash-resilient)
# ------------------------------------------------------------------------------
show_spinner() {
    local pid=$1
    local msg="$2"
    local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local colors=("${C_CYAN}" "${C_PINK}" "${C_WHITE}" "${C_MAGENTA}" "${C_VIOLET}")
    local i=0
    
    tput civis 2>/dev/null || true
    
    while kill -0 "$pid" 2>/dev/null; do
        local c="${colors[$((i % ${#colors[@]}))]}"
        printf "\r\e[K ${c}%s\e[0m \e[1m%s\e[0m" "${spin[$i]}" "${msg}" >&2
        i=$(( (i + 1) % ${#spin[@]} ))
        sleep 0.1
    done
    
    tput cnorm 2>/dev/null || true
}

run_with_spinner() {
    local msg="$1"
    shift
    "$@" >> "${LOG_FILE}" 2>&1 &
    local pid=$!
    show_spinner "$pid" "$msg"
    local exit_code=0
    wait "$pid" || exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        printf "\r\e[K ${C_RED}✘${C_RESET} \e[1m%s\e[0m ${C_PINK}(Failed — see log)${C_RESET}\n" "${msg}" >&2
        log_err "${msg} failed with exit code ${exit_code}. Check '${LOG_FILE}' for details."
        return $exit_code
    else
        printf "\r\e[K ${C_GREEN}✔${C_RESET} \e[1m%s\e[0m ${C_CYAN}(Completed)${C_RESET}\n" "${msg}" >&2
    fi
}

# ------------------------------------------------------------------------------
# CLI ARGUMENT PARSER
# ------------------------------------------------------------------------------
show_help() {
    print_banner
    echo -e "\n${C_BOLD}USAGE:${C_RESET}"
    echo -e "  ./harvest_cv.sh [OPTIONS]\n"
    echo -e "${C_BOLD}OPTIONS:${C_RESET}"
    echo -e "  ${C_CYAN}-h, --help${C_RESET}                 Show help documentation"
    echo -e "  ${C_CYAN}-v, --verbose${C_RESET}              Print ISO timestamps & detailed trace in console"
    echo -e "  ${C_CYAN}-l, --log${C_RESET}                  View the latest execution log file in terminal"
    echo -e "  ${C_CYAN}-k, --db, --knowledge${C_RESET}      View the synced technical knowledge database in terminal"
    echo -e "  ${C_CYAN}-a, --add-source <TARGET>${C_RESET} Point to an additional scrapable path, URL, or note"
    echo -e "  ${C_CYAN}--view${C_RESET}                     Open local preview HTML resume in Google Chrome"
    echo -e "  ${C_CYAN}-t, --tailor <FILE|URL>${C_RESET}    Tailor summary, keywords, & bullet points to a Job Description"
    echo -e "  ${C_CYAN}-p, --pdf${C_RESET}                  Force automated headless PDF export"
    echo -e "  ${C_CYAN}-d, --diff${C_RESET}                 Generate visual experience diff log"
    echo -e "  ${C_CYAN}-i, --interactive${C_RESET}          Enable interactive prompt edit & conflict resolution loop"
    echo -e "  ${C_CYAN}-e, --encrypt-mode <TYPE>${C_RESET}  Set encryption backend: 'aes' (default) or 'gpg'"
    echo -e "  ${C_CYAN}--gui${C_RESET}                      Open customization GUI in Google Chrome"
    echo -e "  ${C_CYAN}-c, --config${C_RESET}               Reconfigure GitHub token & private cloud sync options"
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help) show_help ;;
        -v|--verbose) VERBOSE="true"; shift ;;
        -l|--log) VIEW_LOG="true"; shift ;;
        -k|--db|--knowledge) VIEW_DB="true"; shift ;;
        -a|--add-source) MANUAL_SOURCES+=("$2"); shift 2 ;;
        --view) ONLY_VIEW="true"; shift ;;
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

# View Log Mode (-l / --log)
if [[ "${VIEW_LOG}" == "true" ]]; then
    LATEST_LOG="$(ls -t "${LOG_DIR}"/harvest_*.log 2>/dev/null | head -n 1 || echo '')"
    if [[ -n "${LATEST_LOG}" && -f "${LATEST_LOG}" ]]; then
        echo -e "${C_CYAN}◈ Opening latest execution log file: '${LATEST_LOG}'...${C_RESET}"
        if command -v micro &>/dev/null; then
            micro "${LATEST_LOG}"
        else
            less -R "${LATEST_LOG}"
        fi
    else
        echo -e "${C_RED}✘ No log files found in '${LOG_DIR}'.${C_RESET}"
    fi
    exit 0
fi

# View Knowledge Base Mode (--db / -k)
if [[ "${VIEW_DB}" == "true" ]]; then
    DB_TARGET=""
    if [[ -f "${OUTPUT_PROFILE}" ]]; then
        DB_TARGET="${OUTPUT_PROFILE}"
    elif [[ -f "${INPUT_PROFILE}" ]]; then
        DB_TARGET="${INPUT_PROFILE}"
    elif [[ -f "${LOCAL_PREVIEW_DIR}/raw_technical_profile.md" ]]; then
        DB_TARGET="${LOCAL_PREVIEW_DIR}/raw_technical_profile.md"
    fi

    if [[ -n "${DB_TARGET}" ]]; then
        echo -e "${C_CYAN}◈ Opening synced technical knowledge base: '${DB_TARGET}'...${C_RESET}"
        if command -v micro &>/dev/null; then
            micro "${DB_TARGET}"
        else
            less -R "${DB_TARGET}"
        fi
    else
        log_err "No synced knowledge database found. Run ./harvest_cv.sh to generate it."
    fi
    exit 0
fi

if [[ "${ONLY_VIEW}" == "true" ]]; then
    if [[ -f "${LOCAL_PREVIEW_DIR}/cv.html" ]]; then
        log_info "Opening local preview HTML resume in Google Chrome..."
        google-chrome-stable "file://${LOCAL_PREVIEW_DIR}/cv.html" &>/dev/null &
    else
        log_err "No local preview found at './local_preview/cv.html'. Run ./harvest_cv.sh first."
    fi
    exit 0
fi

print_banner
log_info "Starting Vltimate CV Scraper v3.5"
echo -e "${C_CYAN}────────────────────────────────────────────────────────────────────────${C_RESET}"

# ------------------------------------------------------------------------------
# MIGRATE LEGACY CONFIG FILES TO './config/' SUBDIR
# ------------------------------------------------------------------------------
if [[ -f "${SCRIPT_DIR}/.vltimate_config.env" && ! -f "${CONFIG_FILE}" ]]; then
    cp -f "${SCRIPT_DIR}/.vltimate_config.env" "${CONFIG_FILE}"
    chmod 600 "${CONFIG_FILE}"
    log_info "Migrated legacy config to './config/vltimate_config.env'"
fi
if [[ -f "${SCRIPT_DIR}/.pdf_customization.json" && ! -f "${PDF_CUSTOM_FILE}" ]]; then
    cp -f "${SCRIPT_DIR}/.pdf_customization.json" "${PDF_CUSTOM_FILE}"
    log_info "Migrated legacy PDF customization to './config/pdf_customization.json'"
fi
if [[ -f "${SCRIPT_DIR}/.checkpoint.json" && ! -f "${CHECKPOINT_FILE}" ]]; then
    cp -f "${SCRIPT_DIR}/.checkpoint.json" "${CHECKPOINT_FILE}"
    log_info "Migrated legacy checkpoint to './config/checkpoint.json'"
fi

# ------------------------------------------------------------------------------
# INTERRUPTED SESSION RECOVERY (USER-FRIENDLY RECOVERY PROMPT)
# ------------------------------------------------------------------------------
RESUME_STATE=""
if [[ -f "${CHECKPOINT_FILE}" ]]; then
    LAST_STATE="$(grep '"state"' "${CHECKPOINT_FILE}" | cut -d'"' -f4 || echo '')"
    echo ""
    log_warn "✦ Interrupted session detected from previous run!"
    echo "  1) Resume previous session"
    echo "  2) Start fresh run"
    read -r -p "Select recovery option [1/2]: " RECOVERY_CHOICE || RECOVERY_CHOICE="2"
    if [[ "${RECOVERY_CHOICE}" == "1" ]]; then
        RESUME_STATE="${LAST_STATE}"
        log_info "Resuming session from last saved state..."
    else
        clear_checkpoint
        log_info "Discarded previous session state. Starting fresh run..."
    fi
fi

# ------------------------------------------------------------------------------
# STEP 0: System Dependency Verification & Subdirectory Init
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
mkdir -p "${INPUT_DIR}" "${OUTPUT_DIR}" "${ARCHIVE_DIR}" "${LOCAL_PREVIEW_DIR}"

rm -f "${SCRIPT_DIR}/cv_en.html" "${SCRIPT_DIR}/cv_pl.html" "${SCRIPT_DIR}/cv_en.pdf" "${SCRIPT_DIR}/cv_pl.pdf" "${SCRIPT_DIR}/raw_technical_profile.md"

# ------------------------------------------------------------------------------
# DYNAMIC HEURISTIC UN-PREDETERMINED DISCOVERY ENGINE
# ------------------------------------------------------------------------------
discover_dynamic_sources() {
    local SCRIPT_COUNT=0
    local REPO_COUNT=0
    local EXTRA_COUNT=${#MANUAL_SOURCES[@]}

    for d in "${HOME}/.local/bin" "${HOME}/bin" "${HOME}/Scripts" "/opt"; do
        if [[ -d "$d" ]]; then
            SCRIPT_COUNT=$((SCRIPT_COUNT + 1))
            echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] ℹ Dynamic source identified: Script Directory '$d'" >> "${LOG_FILE}"
        fi
    done
    
    while IFS= read -r gitdir; do
        if [[ -n "$gitdir" ]]; then
            local repo_path="$(dirname "$gitdir")"
            echo "[$(date -u +'%Y-%m-%dT%H:%M:%SZ')] ℹ Dynamic source identified: Git Repository '${repo_path}'" >> "${LOG_FILE}"
            REPO_COUNT=$((REPO_COUNT + 1))
            if [[ $REPO_COUNT -ge 15 ]]; then break; fi
        fi
    done < <(find "${HOME}" -maxdepth 3 -name ".git" 2>/dev/null || true)
    
    log_info "✦ Dynamic Intelligence Discovery: Found ${REPO_COUNT} Local Git Repos, ${SCRIPT_COUNT} Binary Directories, and Shell Environments"
    if [[ $EXTRA_COUNT -gt 0 ]]; then
        log_info "✦ Manual Targets Added: ${EXTRA_COUNT} custom paths/URLs ingested"
    fi
}

discover_dynamic_sources

# ------------------------------------------------------------------------------
# STEP 1: Customization Memory & GUI Trigger Logic
# ------------------------------------------------------------------------------
# Auto-check Downloads before prompting
pickup_downloaded_customization

if [[ -f "${PDF_CUSTOM_FILE}" && "${OPEN_GUI}" != "true" ]]; then
    log_info "Existing layout customization found in './config/pdf_customization.json'."
    read -r -p "❖ Re-open Chrome HTML GUI to change layout options? [y/N]: " OPEN_GUI_PROMPT || OPEN_GUI_PROMPT="n"
    if [[ "${OPEN_GUI_PROMPT}" =~ ^[Yy](es)?$ ]]; then
        OPEN_GUI="true"
    fi
fi

if [[ "${OPEN_GUI}" == "true" || ! -f "${PDF_CUSTOM_FILE}" ]]; then
    if [[ ! -f "${PDF_CUSTOM_FILE}" ]]; then
        if [[ -f "${CONFIG_DIR}/pdf_customization.template.json" ]]; then
            cp -f "${CONFIG_DIR}/pdf_customization.template.json" "${PDF_CUSTOM_FILE}"
        else
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
        fi
        log_info "Created layout customization from default template."
    fi

    log_info "Opening layout customization GUI in Google Chrome..."
    if [[ -f "${OUTPUT_CV_HTML}" ]]; then
        google-chrome-stable "file://${OUTPUT_CV_HTML}" &>/dev/null &
    elif [[ -f "${LOCAL_PREVIEW_DIR}/cv.html" ]]; then
        google-chrome-stable "file://${LOCAL_PREVIEW_DIR}/cv.html" &>/dev/null &
    elif [[ -f "${TEMPLATE_FILE}" ]]; then
        google-chrome-stable "file://${TEMPLATE_FILE}" &>/dev/null &
    else
        log_warn "No HTML resume or template found to open. Skipping GUI."
    fi
    echo ""
    read -r -p "❖ Adjust options in Chrome, click 'Save Config', then press Enter to continue: " _UNUSED || true
    
    # Auto-pick up downloaded customization config or enter fallback retry loop
    while true; do
        if pickup_downloaded_customization; then
            break
        else
            echo ""
            echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
            log_warn "▲ No new exported customization config file detected in ~/Downloads/!"
            echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
            echo "Instructions: In Chrome, click 'Save Config' to export 'pdf_customization.json'."
            echo ""
            echo "Options:"
            echo "  1) Retry auto-detecting in ~/Downloads/ (if download was delayed)"
            echo "  2) Enter file path or directory path manually"
            echo "  3) Continue using current/default customization config"
            read -r -p "Select option [1-3] (Default: 1): " FALLBACK_CHOICE || FALLBACK_CHOICE="1"
            FALLBACK_CHOICE="${FALLBACK_CHOICE:-1}"

            case "${FALLBACK_CHOICE}" in
                1)
                    log_info "Re-checking ~/Downloads/..."
                    sleep 0.5
                    ;;
                2)
                    read -r -p "❖ Enter file or directory path: " MANUAL_PATH || MANUAL_PATH=""
                    if [[ -n "${MANUAL_PATH}" ]]; then
                        if search_and_move_customization "${MANUAL_PATH}"; then
                            break
                        else
                            log_warn "Could not find any 'pdf_customization*.json' at '${MANUAL_PATH}'."
                        fi
                    fi
                    ;;
                3)
                    log_info "Continuing with configuration in './config/pdf_customization.json'."
                    break
                    ;;
                *)
                    log_warn "Invalid selection. Retrying..."
                    ;;
            esac
        fi
    done
fi

# ------------------------------------------------------------------------------
# STEP 2: Persistent Configuration & GitHub Token Verification
# ------------------------------------------------------------------------------
CLOUD_SYNC_ENABLED="false"
VAULT_REPO="vltimate-cv-vault"
PUBLIC_REPO="vltimate-cv-scraper"

if [[ -f "${CONFIG_FILE}" ]]; then
    # shellcheck disable=SC1090
    source "${CONFIG_FILE}"
fi

# Override with environment variable if present
if [[ -n "${GH_TOKEN:-}" ]]; then GITHUB_TOKEN="${GH_TOKEN}"; fi

# Helper: persist current config values to disk
save_config() {
    cat <<EOF > "${CONFIG_FILE}"
CLOUD_SYNC_ENABLED="${CLOUD_SYNC_ENABLED}"
GITHUB_USER="${GITHUB_USER}"
GITHUB_TOKEN="${GITHUB_TOKEN}"
VAULT_REPO="${VAULT_REPO}"
PUBLIC_REPO="${PUBLIC_REPO}"
EOF
    chmod 600 "${CONFIG_FILE}"
    log_info "Config saved to './config/vltimate_config.env'."
}

if [[ "${CLOUD_SYNC_ENABLED}" == "true" && -z "${GITHUB_TOKEN:-}" && "${RECONFIG}" != "true" ]]; then
    echo ""
    log_warn "Private Cloud Sync is enabled, but no GitHub Personal Access Token (PAT) is configured!"
    GITHUB_TOKEN="$(read_secret "🗝 Enter your GitHub Personal Access Token (PAT): ")"
    if [[ -n "${GITHUB_TOKEN}" ]]; then
        save_config
    else
        log_warn "No token provided. Private Cloud Sync will be skipped for this run."
    fi
elif [[ "${RECONFIG}" == "true" || ! -f "${CONFIG_FILE}" ]]; then
    echo ""
    read -r -p "⚡ Enable Private GitHub Cloud Sync for encrypted vault database? [y/N]: " SYNC_PROMPT || SYNC_PROMPT="n"
    if [[ "${SYNC_PROMPT}" =~ ^[Yy](es)?$ ]]; then
        CLOUD_SYNC_ENABLED="true"
        if [[ -z "${GITHUB_USER:-}" || "${GITHUB_USER}" == "Vikyek" ]]; then
            read -r -p "👤 Enter your GitHub Username [default: Vikyek]: " GITHUB_USER || GITHUB_USER="Vikyek"
            GITHUB_USER="${GITHUB_USER:-Vikyek}"
        else
            log_info "Detected GitHub Username: '${GITHUB_USER}'"
        fi

        if [[ -z "${GITHUB_TOKEN:-}" ]]; then
            GITHUB_TOKEN="$(read_secret "🗝 Enter your GitHub Personal Access Token (PAT): ")"
        else
            log_info "Detected GitHub Personal Access Token from environment variable."
        fi

        read -r -p "◆ Enter Private Vault Repo Name [default: ${VAULT_REPO}]: " INPUT_REPO || INPUT_REPO=""
        if [[ -n "${INPUT_REPO}" ]]; then VAULT_REPO="${INPUT_REPO}"; fi

        save_config
    fi
fi

# ------------------------------------------------------------------------------
# STEP 3: Private Cloud Vault Pull & Pre-Harvest Decryption
# ------------------------------------------------------------------------------
if [[ "${CLOUD_SYNC_ENABLED:-}" == "true" && -n "${GITHUB_USER:-}" && -n "${GITHUB_TOKEN:-}" ]]; then
    log_info "Connecting to Private GitHub Vault '${GITHUB_USER}/${VAULT_REPO}'..."
    rm -rf "${VAULT_DIR}"
    VAULT_URL="https://${GITHUB_USER}:${GITHUB_TOKEN}@github.com/${GITHUB_USER}/${VAULT_REPO}.git"

    if git ls-remote "${VAULT_URL}" &>/dev/null; then
        log_info "Pulling latest encrypted database from private cloud vault..."
        git clone --quiet "${VAULT_URL}" "${VAULT_DIR}"
        if [[ -f "${VAULT_DIR}/personal_data.tar.gz.enc" ]]; then
            cp -f "${VAULT_DIR}/personal_data.tar.gz.enc" "${ENCRYPTED_ARCHIVE}"
            log_info "Latest encrypted cloud database downloaded."
        fi
    else
        log_info "Private vault repository '${GITHUB_USER}/${VAULT_REPO}' will be created upon first encryption."
    fi
elif [[ "${CLOUD_SYNC_ENABLED:-}" == "true" && -z "${GITHUB_TOKEN:-}" ]]; then
    log_warn "Skipping Private Cloud Sync — no GitHub Token. Run './harvest_cv.sh -c' to configure."
fi

# ------------------------------------------------------------------------------
# STEP 4: Auto-detect, Decrypt & Subdirectory Snapshot Lifecycle
# ------------------------------------------------------------------------------
if [[ -z "${RESUME_STATE}" || "${RESUME_STATE}" == "STATE_DECRYPTED" ]]; then
    if [[ -f "${ENCRYPTED_ARCHIVE}" ]]; then
        log_info "Encrypted personal archive detected: './personal_data.tar.gz.enc'"
        if [[ -n "${DECRYPT_PASS:-}" ]]; then
            log_info "Using decryption password from environment variable."
        else
            DECRYPT_PASS="$(read_secret "🗝 Enter decryption password: ")"
        fi

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
        local_ts="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
        echo "[${local_ts}] ℹ Creating snapshot archive: './archives/snapshot_${TIMESTAMP}.tar.gz'" >> "${LOG_FILE}"
        if [[ "${VERBOSE}" == "true" ]]; then
            echo -e "${C_DIM}[${local_ts}]${C_RESET} ${C_VIOLET}◈ Snapshot archive created: './archives/snapshot_${TIMESTAMP}.tar.gz'${C_RESET}"
        fi
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
        log_err "System prompt missing at './cv_harvester_system_prompt.md'"
        exit 1
    fi

    PROMPT="Read '${SYSTEM_PROMPT_FILE}' and '${INPUT_PROFILE}'."

    if [[ -n "${TAILOR_TARGET}" ]]; then
        log_info "Job Description Tailoring Mode Enabled for: '${TAILOR_TARGET}'"
        if [[ -f "${TAILOR_TARGET}" ]]; then
            JD_CONTENT="$(cat "${TAILOR_TARGET}")"
        else
            JD_CONTENT="$(curl -s "${TAILOR_TARGET}" || echo "${TAILOR_TARGET}")"
        fi
        PROMPT="${PROMPT} Tailor the summary, keyword badges, and experience bullet points specifically for Job Description: ${JD_CONTENT}."
    fi

    if [[ ${#MANUAL_SOURCES[@]} -gt 0 ]]; then
        PROMPT="${PROMPT} Additionally inspect these user-specified manual targets: ${MANUAL_SOURCES[*]}."
    fi

    # Intelligence source reporting instructions
    PROMPT="${PROMPT} Perform harvesting across system, shell history, git repos, cloud services (gcloud, az, aws, rclone), public registries (Docker Hub, npm, PyPI), and GitHub profile."
    PROMPT="${PROMPT} Perform dynamic heuristic searching to evaluate un-predetermined scrapable places (custom scripts, config dirs, dotfile repos, journals)."
    PROMPT="${PROMPT} When scanning, report each new intelligence source found (e.g. 'Scanning local git repos...', 'Found GitHub repo: <name> [NEW]', 'Scanning shell history...', 'Found loose script: <path> [KNOWN]', 'Scanning online GitHub profile...', 'Found linked profile: <url> [NEW]'). Mark sources as [NEW] if not present in past collected intel, or [KNOWN] if already present."
    PROMPT="${PROMPT} Save updated knowledge base into '${OUTPUT_PROFILE}' and generate unified bilingual interactive HTML resume into '${OUTPUT_CV_HTML}'."

    save_checkpoint "STATE_HARVEST_STARTED"
    if run_with_spinner "Harvesting technical intelligence with agy..." agy --dangerously-skip-permissions --print "${PROMPT}"; then
        save_checkpoint "STATE_HARVEST_COMPLETED"
    else
        log_err "Intelligence harvesting failed or timed out."
        log_warn "You can retry by running './harvest_cv.sh' again (checkpoint will offer resume)."
        echo ""
        echo "  1) Retry harvest now"
        echo "  2) Continue anyway (use existing data in './output/' if available)"
        echo "  3) Abort"
        read -r -p "Select option [1-3]: " RECOVERY_CHOICE || RECOVERY_CHOICE="3"
        case "${RECOVERY_CHOICE}" in
            1)
                log_info "Retrying intelligence harvest..."
                if run_with_spinner "Retrying harvest with agy..." agy --dangerously-skip-permissions --print "${PROMPT}"; then
                    save_checkpoint "STATE_HARVEST_COMPLETED"
                else
                    log_err "Retry also failed. Continuing with existing data..."
                fi
                ;;
            2)
                log_warn "Continuing with existing data in './output/'..."
                ;;
            3)
                log_info "Aborted by user."
                exit 0
                ;;
        esac
    fi
fi

# ------------------------------------------------------------------------------
# STEP 5B: Automated Data Conflict Audit & Conditional Resolution Gate
# ------------------------------------------------------------------------------
if [[ -f "${OUTPUT_PROFILE}" ]]; then
    AUDIT_PROMPT="Read '${OUTPUT_PROFILE}'. Perform a strict conflict & inconsistency audit. Check for conflicting dates, contradictory technical entries, or duplicate experience claims. Write a JSON result into '${AUDIT_FILE}' formatted as: {\"has_conflicts\": false, \"conflicts\": []} if clean, or {\"has_conflicts\": true, \"conflicts\": [\"description of conflict\"]} if issues are found."

    run_with_spinner "Executing automated data conflict audit with agy..." agy --dangerously-skip-permissions --print "${AUDIT_PROMPT}" || true

    HAS_CONFLICTS="false"
    if [[ -f "${AUDIT_FILE}" ]]; then
        if grep -q '"has_conflicts": true' "${AUDIT_FILE}" || grep -q '"has_conflicts":true' "${AUDIT_FILE}"; then
            HAS_CONFLICTS="true"
        fi
    fi

    if [[ "${HAS_CONFLICTS}" == "true" ]]; then
        echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
        log_warn "▲ CONFLICT DETECTED IN HARVESTED TECHNICAL DATA!"
        echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
        cat "${AUDIT_FILE}"
        echo -e "${C_CYAN}────────────────────────────────────────────────────────────────────────${C_RESET}"
        log_warn "Conflict resolution is REQUIRED before proceeding to PDF generation!"
        
        while [[ "${HAS_CONFLICTS}" == "true" ]]; do
            read -r -p "💬 Enter your instruction / resolution for agy: " RESOLUTION_INPUT || RESOLUTION_INPUT=""
            if [[ -n "${RESOLUTION_INPUT}" ]]; then
                RESOLVE_PROMPT="Read '${OUTPUT_PROFILE}' and '${OUTPUT_CV_HTML}'. Resolve this conflict according to user instruction: ${RESOLUTION_INPUT}. Update both files, then re-audit and update '${AUDIT_FILE}' with has_conflicts: false if resolved."
                run_with_spinner "Applying conflict resolution pass with agy..." agy --dangerously-skip-permissions --print "${RESOLVE_PROMPT}" || true
                
                if grep -q '"has_conflicts": false' "${AUDIT_FILE}" 2>/dev/null || grep -q '"has_conflicts":false' "${AUDIT_FILE}" 2>/dev/null; then
                    HAS_CONFLICTS="false"
                    log_info "✔ Conflict successfully resolved!"
                else
                    log_warn "Re-audit indicates lingering conflicts. Please provide additional resolution detail."
                fi
            fi
        done
    else
        echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
        log_info "✔ Technical Data Audit Passed: Zero data conflicts or date contradictions detected."
        echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
    fi
else
    log_warn "No output profile found. Skipping conflict audit."
fi

# ------------------------------------------------------------------------------
# STEP 6: Interactive Prompt Refinement Menu
# ------------------------------------------------------------------------------
if [[ "${INTERACTIVE_LOOP}" == "true" ]]; then
    while true; do
        echo ""
        echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
        echo -e "${C_BOLD}${C_MAGENTA}✦ Interactive Refinement Menu (via agy)${C_RESET}"
        echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
        echo "Current harvested profile and HTML resume are ready in './output/'."
        echo "  1) Approve current CV & Profile (Proceed to PDF Export & Encryption)"
        echo "  2) Prompt agy to revise / edit specific section"
        echo "  3) Add custom pointers, notes, or new technical entries"
        echo "  4) Re-run full intelligence harvest"
        read -r -p "Select option [1-4]: " EDIT_CHOICE || EDIT_CHOICE="1"

        case "${EDIT_CHOICE}" in
            1)
                log_info "Profile & CV approved by user."
                save_checkpoint "STATE_REVISION_APPROVED"
                break
                ;;
            2|3)
                echo ""
                read -r -p "💬 Enter your instruction / revision for agy: " USER_FEEDBACK || USER_FEEDBACK=""
                if [[ -n "${USER_FEEDBACK}" ]]; then
                    REVISE_PROMPT="Read '${SYSTEM_PROMPT_FILE}', '${OUTPUT_PROFILE}', and '${OUTPUT_CV_HTML}'. Apply instruction: ${USER_FEEDBACK}. Update '${OUTPUT_PROFILE}' and '${OUTPUT_CV_HTML}'."
                    run_with_spinner "Executing revision pass with agy..." agy --dangerously-skip-permissions --print "${REVISE_PROMPT}" || true
                    log_info "Revision applied."
                fi
                ;;
            4)
                run_with_spinner "Re-running full intelligence harvest with agy..." agy --dangerously-skip-permissions --print "${PROMPT}" || true
                ;;
            *)
                log_warn "Invalid option. Select 1 to approve."
                ;;
        esac
    done
fi

# ------------------------------------------------------------------------------
# STEP 7: Headless PDF Generation & Persistent Local Preview Creation
# ------------------------------------------------------------------------------
if [[ -f "${OUTPUT_CV_HTML}" ]]; then
    run_with_spinner "Rendering pixel-perfect headless PDFs..." google-chrome-stable --headless --disable-gpu --print-to-pdf="${OUTPUT_DIR}/cv_en.pdf" "file://${OUTPUT_CV_HTML}" || true
    google-chrome-stable --headless --disable-gpu --print-to-pdf="${OUTPUT_DIR}/cv_pl.pdf" "file://${OUTPUT_CV_HTML}" &>/dev/null || true
    log_info "Rendered './output/cv_en.pdf' & './output/cv_pl.pdf'"
    save_checkpoint "STATE_PDF_RENDERED"

    # Populate Persistent Local Unencrypted Preview Subdirectory (Never uploaded/synced)
    mkdir -p "${LOCAL_PREVIEW_DIR}"
    if [[ -f "${OUTPUT_PROFILE}" ]]; then cp -f "${OUTPUT_PROFILE}" "${LOCAL_PREVIEW_DIR}/raw_technical_profile.md"; fi
    if [[ -f "${OUTPUT_CV_HTML}" ]]; then cp -f "${OUTPUT_CV_HTML}" "${LOCAL_PREVIEW_DIR}/cv.html"; fi
    if [[ -f "${OUTPUT_DIR}/cv_en.pdf" ]]; then cp -f "${OUTPUT_DIR}/cv_en.pdf" "${LOCAL_PREVIEW_DIR}/cv_en.pdf"; fi
    if [[ -f "${OUTPUT_DIR}/cv_pl.pdf" ]]; then cp -f "${OUTPUT_DIR}/cv_pl.pdf" "${LOCAL_PREVIEW_DIR}/cv_pl.pdf"; fi
    log_info "Saved persistent local preview to './local_preview/'"
fi

if [[ "${ENABLE_DIFF}" == "true" && -f "${INPUT_PROFILE}" && -f "${OUTPUT_PROFILE}" ]]; then
    log_info "Visual Experience Diff Tracking..."
    {
        echo "=== Vltimate CV Scraper Diff Report: $(date -u +'%Y-%m-%dT%H:%M:%SZ') ==="
        diff -u "${INPUT_PROFILE}" "${OUTPUT_PROFILE}" || true
    } > "${DIFF_LOG_FILE}"
    log_info "Diff report saved to './harvest_diff.log'"
fi

# ------------------------------------------------------------------------------
# STEP 8: DEFAULT ENCRYPTION POLICY & SECURITY CLEANUP (Default: YES)
# ------------------------------------------------------------------------------
echo ""
read -r -p "◆ Pack and encrypt personal results now? [Y/n]: " PACK_CHOICE || PACK_CHOICE="Y"
PACK_CHOICE="${PACK_CHOICE:-Y}"

if [[ "${PACK_CHOICE}" =~ ^[Yy](es)?$ ]]; then
    # Interactive encryption method selection if not passed via CLI flag
    if [[ "${ENCRYPT_MODE}" == "aes" ]]; then
        echo "🗝 Select encryption method:"
        echo "  1) OpenSSL AES-256 (default)"
        echo "  2) GPG key encryption"
        read -r -p "Selection [1/2]: " METHOD_CHOICE || METHOD_CHOICE="1"
        if [[ "${METHOD_CHOICE}" == "2" ]]; then
            ENCRYPT_MODE="gpg"
        fi
    fi

    if [[ -n "${ENCRYPT_PASS:-}" ]]; then
        log_info "Using encryption password from environment variable."
        ENCRYPT_PASS1="${ENCRYPT_PASS}"
    else
        ENCRYPT_PASS1="$(read_secret "🗝 Enter custom encryption password: ")"
        ENCRYPT_PASS2="$(read_secret "🗝 Re-enter encryption password: ")"

        if [[ "${ENCRYPT_PASS1}" != "${ENCRYPT_PASS2}" || -z "${ENCRYPT_PASS1}" ]]; then
            log_err "Invalid password or mismatch! Aborting encryption."
            exit 1
        fi
    fi

    log_info "Packing './input/', './output/', and './archives/'..."
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
        log_info "Uploading encrypted archive to Private GitHub Cloud Vault..."
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
        log_info "Synced to private GitHub repo: '${GITHUB_USER}/${VAULT_REPO}'"
    elif [[ "${CLOUD_SYNC_ENABLED:-}" == "true" && -z "${GITHUB_TOKEN:-}" ]]; then
        log_warn "Skipped private cloud push — no GitHub Token. Run './harvest_cv.sh -c' to configure."
    fi

    log_info "Security cleanup: Removing unencrypted plain subdirectories..."
    rm -rf "${INPUT_DIR}" "${OUTPUT_DIR}" "${ARCHIVE_DIR}"
    clear_checkpoint

    echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
    log_info "Personal data successfully packed, encrypted, and cleaned!"
    log_info "Encrypted Archive: './personal_data.tar.gz.enc'"
    echo -e "${C_CYAN}────────────────────────────────────────────────────────────────────────${C_RESET}"
    log_info "📄 Local preview available in './local_preview/':"
    log_info "   - Technical Profile: './local_preview/raw_technical_profile.md'"
    log_info "   - Interactive HTML:  './local_preview/cv.html'"
    log_info "   - English PDF:       './local_preview/cv_en.pdf'"
    log_info "   - Polish PDF:        './local_preview/cv_pl.pdf'"
    echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
else
    log_warn "User selected unencrypted mode. Plain assets remain available in './'."
    clear_checkpoint
fi

echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
log_info "Vltimate CV Scraper v3.5 workflow complete!"
echo -e "${C_CYAN}════════════════════════════════════════════════════════════════════════${C_RESET}"
