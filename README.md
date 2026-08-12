# Vltimate CV Scraper v2.1

An automated, privacy-conscious resume architecture, technical intelligence harvester, and job-tailoring suite built for software engineers, game developers, and systems specialists. Powered by **Antigravity CLI (`agy`)**, **OpenSSL AES-256 / GPG encryption**, **Google Chrome headless PDF rendering**, and **Tailwind CSS single-column ATS layout engine**.

---

## 🌟 Key Features

- **Unified Interactive Bilingual HTML (`output/cv.html`)**: Consolidates English and Polish pages into a single interactive document with on-the-fly language toggling, theme switching, and RODO clause injectors.
- **Save & Export Customization**: Click "Save Config" in the HTML toolbar to export your visual themes, font density, language preferences, and RODO choices directly into `.pdf_customization.json`.
- **AI Auto-Translation Engine**: Select or write-in any target language (e.g. Spanish, German, French, Italian, Japanese). Displays a clear translation warning banner and disables PDF export until `agy` completes the translation.
- **Private Configuration Vault (`gemini-config-vault`)**: Synchronizes master learned rules (`GEMINI.md`), machine-specific environment scopes, and preferences to a private GitHub repository (`https://github.com/Vikyek/gemini-config-vault.git`) located at `~/.gemini/config/`.
- **Development Sandbox (`devel/`) & Safe Promotion**: Contains experimental beta features (Font density selector, typography switcher, ATS pre-flight scorecard, QR code generator). Isolated from main Git tracking via `.gitignore`. Features `devel/promote_devel.sh` for safe, single-command promotion to production.
- **Subdirectory Tree & Snapshot Lifecycle**:
  - `input/`: Baseline technical profile data automatically rotated from previous runs to build upon.
  - `output/`: Freshly generated resume assets (`raw_technical_profile.md`, `cv.html`, `cv_en.pdf`, `cv_pl.pdf`).
  - `archives/`: Timestamped compressed snapshots (`snapshot_YYYY-MM-DD_HHMMSS.tar.gz`) of previous runs.
- **Automated Data Harvesting**: Scans local OS specs, shell command history, git configurations, and remote GitHub profile repositories (`github.com/Vikyek`).
- **Autonomous Repository Sync**: Automatically syncs public code repositories (`vltimate-cv-scraper`) and private encrypted vault repositories (`vltimate-cv-vault` & `gemini-config-vault`) on GitHub via API tokens/SSH without manual prompts.
- **Headless PDF Generation**: Automatically renders pixel-perfect PDF files (`output/cv_en.pdf` and `output/cv_pl.pdf`) using Google Chrome. Saves preferences in `.pdf_customization.json`.
- **Job Description (JD) Tailoring (`--tailor <file_or_url>`)**: Dynamically aligns your resume summary, keyword tag cloud, and experience bullet points specifically for a target role.
- **Visual Experience Diff Tracker (`--diff`)**: Tracks newly harvested technical experience across runs (`harvest_diff.log`).
- **Dual Encryption Engine (`--encrypt-mode <aes|gpg>`)**: Supports OpenSSL AES-256-CBC and GPG key encryption modes.
- **Full Security Cleanup**: Automatically wipes unencrypted plain text `input/`, `output/`, and `archives/` subdirectories after encryption to ensure personal data exists ONLY inside the encrypted archive.

---

## 📁 Subdirectory Tree & Repository Structure

```
.
├── cv_harvester_system_prompt.md  # Master system prompt & enterprise ATS screening rules
├── cv_template.html               # Production ModernCV layout container template
├── harvest_cv.sh                  # Interactive CLI harvester & encryption runner script
├── man/man1/vltimate-cv-scraper.1 # UNIX man page documentation
├── README.md                      # Project documentation
├── .gitignore                     # Git exclusions for encrypted archives & private data
│
│--- DEVELOPMENT & BETA SANDBOX (Gitignored) ---
├── devel/                         # Beta sandbox directory (Density, Fonts, ATS Scorecard, QR)
│   ├── cv_template.html           # Experimental beta template
│   ├── harvest_cv.sh              # Experimental runner
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

## 🚀 CLI Usage & Options

```text
USAGE:
  ./harvest_cv.sh [OPTIONS]

OPTIONS:
  -h, --help                Show help documentation
  -t, --tailor <FILE|URL>   Tailor summary, keywords, & bullet points to a Job Description
  -p, --pdf                 Force automated headless PDF export (output/cv_en.pdf & cv_pl.pdf)
  -d, --diff                Generate visual experience diff log (harvest_diff.log)
  -e, --encrypt-mode <TYPE> Set encryption backend: 'aes' (OpenSSL AES-256) or 'gpg'
  --gui                     Open customization GUI in Google Chrome to set themes/RODO options
  -c, --config              Reconfigure GitHub token & private cloud sync options
```

---

## 📖 UNIX Man Page
To view the manual page:
```bash
man ./man/man1/vltimate-cv-scraper.1
```

---

## 🔐 Security & Privacy Note
Sensitive data, personal contact details, subdirectories (`input/`, `output/`, `archives/`, `devel/`), credentials (`.vltimate_config.env`), and customization settings (`.pdf_customization.json`) are strictly excluded from git tracking via `.gitignore`.
