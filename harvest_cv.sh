#!/usr/bin/env bash
# ==============================================================================
# Automated CV Harvester, Resume Engine & Encryption Suite
# Usage: ./harvest_cv.sh
# Supports: Auto-detecting & decrypting existing archives, system harvesting via agy,
#           and interactively packing & encrypting personal results with AES-256
#           followed by a full security cleanup of unencrypted data.
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"
mkdir -p "${OUTPUT_DIR}"

SYSTEM_PROMPT_FILE="${SCRIPT_DIR}/cv_harvester_system_prompt.md"
RAW_PROFILE_FILE="${SCRIPT_DIR}/raw_technical_profile.md"
CV_EN_FILE="${SCRIPT_DIR}/cv_en.html"
CV_PL_FILE="${SCRIPT_DIR}/cv_pl.html"

ENCRYPTED_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz.enc"
PLAIN_ARCHIVE="${SCRIPT_DIR}/personal_data.tar.gz"

echo "======================================================================"
echo "🚀 Technical Intelligence Harvester & Encryption Suite"
echo "Working Directory: ${SCRIPT_DIR}"
echo "======================================================================"

# ------------------------------------------------------------------------------
# STEP 1: Auto-detect & Read Packed / Encrypted Results
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
# STEP 2: Execute agy Intelligence Harvesting & CV Generation
# ------------------------------------------------------------------------------
if [[ ! -f "${SYSTEM_PROMPT_FILE}" ]]; then
    echo "Error: System prompt missing at ${SYSTEM_PROMPT_FILE}" >&2
    exit 1
fi

PROMPT="Read '${SYSTEM_PROMPT_FILE}' and '${RAW_PROFILE_FILE}'. Perform the technical data harvesting workflow across the local system, shell history, git repos, and GitHub profile. Update '${RAW_PROFILE_FILE}', '${CV_EN_FILE}', and '${CV_PL_FILE}'. Save identical copies of all updated assets into '${OUTPUT_DIR}'."

if command -v agy &>/dev/null; then
    echo "======================================================================"
    echo "⚡ Harvesting technical intelligence with agy..."
    echo "======================================================================"
    agy --dangerously-skip-permissions --print "${PROMPT}"
else
    echo "⚠️ 'agy' CLI command not found in PATH. Skipping automated harvest phase." >&2
fi

# Synchronize fallback copies to output dir
cp -f "${RAW_PROFILE_FILE}" "${OUTPUT_DIR}/raw_technical_profile.md" 2>/dev/null || true
if [[ -f "${CV_EN_FILE}" ]]; then cp -f "${CV_EN_FILE}" "${OUTPUT_DIR}/cv_en.html" 2>/dev/null || true; fi
if [[ -f "${CV_PL_FILE}" ]]; then cp -f "${CV_PL_FILE}" "${OUTPUT_DIR}/cv_pl.html" 2>/dev/null || true; fi

echo "======================================================================"
echo "✅ Harvesting & CV Generation Phase Finished!"
echo "======================================================================"

# ------------------------------------------------------------------------------
# STEP 3: Interactive Prompt for Packing, Encryption & Security Cleanup
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

    echo "🧹 Executing security cleanup: Removing unencrypted plain text files..."
    rm -rf "${RAW_PROFILE_FILE}" "${CV_EN_FILE}" "${CV_PL_FILE}" "${OUTPUT_DIR}"

    echo "======================================================================"
    echo "✅ Personal data successfully packed and encrypted!"
    echo "👉 Encrypted Archive: ${ENCRYPTED_ARCHIVE}"
    echo "🔒 All unencrypted plain text files have been securely removed."
    echo "======================================================================"
else
    echo "ℹ️ Skipping encryption. Plain assets remain available locally in ${SCRIPT_DIR}."
fi

echo "======================================================================"
echo "🎉 Workflow complete!"
echo "======================================================================"
