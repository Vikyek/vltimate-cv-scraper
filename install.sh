#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"
MAN_DIR="${HOME}/.local/share/man/man1"

echo "=== Installing Vltimate CV Scraper ==="

mkdir -p "${BIN_DIR}"
mkdir -p "${MAN_DIR}"

cat <<'LAUNCHER' > "${BIN_DIR}/vltimate-cv-scraper"
#!/usr/bin/env bash
REAL_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
DIR_PATH="$(dirname "$REAL_DIR")/vltimate-cv-scraper"
if [ ! -f "${DIR_PATH}/harvest_cv.sh" ]; then
    DIR_PATH="${HOME}/Projects/vltimate-cv-scraper"
fi
if [ -f "${DIR_PATH}/harvest_cv.sh" ]; then
    bash "${DIR_PATH}/harvest_cv.sh" "$@"
else
    bash "$(dirname "${BASH_SOURCE[0]}")/harvest_cv.sh" "$@"
fi
LAUNCHER
chmod +x "${BIN_DIR}/vltimate-cv-scraper"

ln -sf "${BIN_DIR}/vltimate-cv-scraper" "${BIN_DIR}/harvest-cv"

if [ -f "${SCRIPT_DIR}/man/man1/vltimate-cv-scraper.1" ]; then
    install -Dm644 "${SCRIPT_DIR}/man/man1/vltimate-cv-scraper.1" "${MAN_DIR}/vltimate-cv-scraper.1"
    echo "Installed man page to ${MAN_DIR}/vltimate-cv-scraper.1"
fi

echo "Vltimate CV Scraper installed successfully!"
echo "Commands: vltimate-cv-scraper, harvest-cv"
