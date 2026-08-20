# Vltimate CV Scraper v3.0

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

An automated, privacy-conscious resume architecture, technical intelligence harvester, and job-tailoring suite built for software engineers, game developers, and systems specialists. Powered by **Antigravity CLI (`agy`)**, **OpenSSL AES-256 / GPG encryption**, **Google Chrome headless PDF rendering**, and **Tailwind CSS single-column ATS layout engine**.

---

## 📋 Requirements & Prerequisites

- **Shell:** `bash` (4.0+)
- **Security & Encryption:**
  - `openssl` (for AES-256 encryption)
  - `gnupg` (for GPG key-based encryption)
- **Rendering & Headless Browser:**
  - `google-chrome` or `chromium` (for headless PDF rendering)
  - `fontconfig` and `noto-fonts-emoji` (for font and emoji symbol rendering)
- **AI Agent Engine:**
  - `agy` (Antigravity CLI)

Install dependencies on Arch Linux:
```bash
sudo pacman -S bash openssl gnupg chromium fontconfig noto-fonts-emoji
```

---

## 🌟 Key Features

- **Clean Console Output & Path Formatting**: Clean status messages without ISO timestamp clutter (unless `-v` / `--verbose` is passed). All file paths printed in quoted relative format (e.g. `'./output/'`, `'./personal_data.tar.gz.enc'`).
- **Layout Customization Memory & Polling GUI**: Detects existing `'./config/pdf_customization.json'` layout settings. When updating via Chrome GUI, it automatically polls and detects newly downloaded config files using timestamp validation (ignoring old configs) to continue execution instantly.
- **Local Key Caching & Auto-Decryption**: Stores the encryption/decryption key securely in a local, gitignored file (`'./config/vault_key.txt'`) upon first successful access to automate decrypt/encrypt steps in subsequent runs.
- **Environment Variable Auto-Detection**: Automatically detects `DECRYPT_PASS`, `ENCRYPT_PASS`, and `GH_TOKEN` from your shell environment to bypass manual prompts in non-interactive runs.
- **Interactive Encryption Method Selector**: Prompts for encryption method selection (`OpenSSL AES-256` or `GPG key`) with standard `[Y/n]` default prompt.
- **Interactive Refinement & Conflict Resolution Loop (`-i`, `--interactive`)**: Menu allowing you to prompt `agy` to resolve technical conflicts, expand specific sections, or add custom pointers/notes live before finalizing PDFs and encryption.
- **Unified Interactive Bilingual HTML (`output/cv.html`)**: Consolidates English and Polish pages into a single interactive document with on-the-fly language toggling, theme switching, and RODO clause injectors.
- **Development Sandbox (`devel/`) & Safe Promotion**: Contains experimental beta features (Font density selector, typography switcher, ATS pre-flight scorecard, QR code generator). Isolated from main Git tracking via `.gitignore`. Features `devel/promote_devel.sh` for safe, single-command promotion to production.
- **Subdirectory Tree & Snapshot Lifecycle**:
  - `input/`: Baseline technical profile data automatically rotated from previous runs to build upon.
  - `output/`: Freshly generated resume assets (`raw_technical_profile.md`, `cv.html`, `cv_en.pdf`, `cv_pl.pdf`).
  - `archives/`: Timestamped compressed snapshots (`snapshot_YYYY-MM-DD_HHMMSS.tar.gz`) of previous runs.

---

## 📁 Subdirectory Tree & Repository Structure

```
.
├── cv_harvester_system_prompt.md  # Master system prompt & enterprise ATS screening rules
├── cv_template.html               # Production ModernCV layout container template
├── harvest_cv.sh                  # Interactive CLI harvester & encryption runner script (v3.0)
├── man/man1/vltimate-cv-scraper.1 # UNIX man page documentation
├── README.md                      # Project documentation
├── .gitignore                     # Git exclusions for encrypted archives & private data
│
│--- DEVELOPMENT & BETA SANDBOX (Gitignored) ---
├── devel/                         # Beta sandbox directory (Density, Fonts, ATS Scorecard, QR)
│   ├── cv_template.html           # Experimental beta template
│   ├── harvest_cv.sh              # Experimental runner (v3.0-DEVEL)
│   └── promote_devel.sh           # Safe promotion script (promotes devel/ to master)
│
│--- DYNAMIC DATA SUBDIRECTORIES (Gitignored / Encrypted) ---
├── input/                         # Baseline technical data rotated from previous run
│   └── raw_technical_profile.md
├── output/                        # Freshly generated resume & knowledge base assets
│   ├── raw_technical_profile.md
│   ├── cv.html                    # Unified interactive bilingual HTML resume (EN/PL)
│   ├── cv_en.pdf                  # Rendered English PDF
│   └── cv_pl.pdf                  # Rendered Polish PDF
└── archives/                      # Timestamped compressed snapshots of prior runs
    └── snapshot_*.tar.gz
```

---

## 🚀 Installation & Setup

### Automated Installation
```bash
git clone https://github.com/Vikyek/vltimate-cv-scraper.git
cd vltimate-cv-scraper
chmod +x install.sh
./install.sh
```

### Manual Installation
```bash
mkdir -p ~/.local/bin ~/.local/share/man/man1
chmod +x harvest_cv.sh
ln -s "$(pwd)/harvest_cv.sh" ~/.local/bin/vltimate-cv-scraper
install -Dm644 man/man1/vltimate-cv-scraper.1 ~/.local/share/man/man1/vltimate-cv-scraper.1
```

---

## 💻 CLI Usage & Options

```text
USAGE:
  harvest_cv.sh [OPTIONS]

OPTIONS:
  -h, --help                Show help documentation
  -v, --verbose             Print ISO timestamps in live console output
  -t, --tailor <FILE|URL>   Tailor summary, keywords, & bullet points to a Job Description
  -p, --pdf                 Force automated headless PDF export (output/cv_en.pdf & cv_pl.pdf)
  -d, --diff                Generate visual experience diff log ('./harvest_diff.log')
  -i, --interactive         Enable interactive prompt edit & conflict resolution loop
  -e, --encrypt-mode <TYPE> Set encryption backend: 'aes' (default) or 'gpg'
  --gui                     Open customization GUI in Google Chrome to set themes/RODO options
  -c, --config              Reconfigure GitHub token & private cloud sync options
```

### Examples
```bash
# Standard interactive harvest & PDF generation
./harvest_cv.sh -p -i

# Tailor resume for a specific job description
./harvest_cv.sh -t job_posting.txt -p
```

---

## 📖 UNIX Man Page
To view the manual page:
```bash
man vltimate-cv-scraper
# Or from project directory:
man ./man/man1/vltimate-cv-scraper.1
```

---

## 🔐 Security & Privacy Note
Sensitive data, personal contact details, subdirectories (`input/`, `output/`, `archives/`, `devel/`, `.agents/`), credentials (`.vltimate_config.env`), and customization settings (`.pdf_customization.json`) are strictly excluded from git tracking via `.gitignore`.

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
