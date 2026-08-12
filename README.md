# Vltimate CV Scraper v2.0

An automated, privacy-conscious resume architecture, technical intelligence harvester, and job-tailoring suite built for software engineers, game developers, and systems specialists. Powered by **Antigravity CLI (`agy`)**, **OpenSSL AES-256 / GPG encryption**, **Google Chrome headless PDF rendering**, and **Tailwind CSS single-column ATS layout engine**.

---

## 🌟 Key Features

- **Automated Data Harvesting**: Scans local OS specs, shell command history, git configurations, and remote GitHub profile repositories (`github.com/Vikyek`).
- **Autonomous Repository Creation**: Automatically creates and syncs both public code repositories (`vltimate-cv-scraper`) and private encrypted vault repositories (`vltimate-cv-vault`) on GitHub via API tokens/SSH without manual prompts.
- **Headless PDF Generation & Customization Memory**: Automatically renders pixel-perfect PDF files ([`cv_en.pdf`](cv_en.pdf) and [`cv_pl.pdf`](cv_pl.pdf)) using Google Chrome. Saves and remembers your layout, theme, and RODO preferences in `.pdf_customization.json`.
- **Job Description (JD) Tailoring (`--tailor <file_or_url>`)**: Dynamically analyzes any job posting URL or text file, aligning your resume summary, keyword tag cloud, and experience bullet points specifically for that target role.
- **Visual Experience Diff Tracker (`--diff`)**: Tracks newly harvested repos, kernel parameters, hardware skills, and tools across runs, generating a structured diff log ([`harvest_diff.log`](harvest_diff.log)).
- **Dual Encryption Engine (`--encrypt-mode <aes|gpg>`)**: Supports OpenSSL AES-256-CBC and GPG key encryption modes with interactive password verification.
- **Full Security Cleanup**: Automatically wipes unencrypted plain text profile and generated resume files after encryption to ensure personal data exists ONLY inside the encrypted archive.
- **Bilingual ATS Resumes**: Maintains synchronized English ([`cv_en.html`](cv_en.html)) and Polish ([`cv_pl.html`](cv_pl.html)) interactive resumes with printable A4 paper sheets and responsive fluid views.

---

## ⚙️ System Dependencies

| Dependency | Purpose | Installation (Arch Linux / `paru`) |
| :--- | :--- | :--- |
| **`agy`** | Antigravity CLI AI Engine | `npm install -g @google/antigravity-cli` / `agy` |
| **`google-chrome-stable`** | Headless PDF Export & GUI | `paru -S google-chrome` |
| **`openssl`** | AES-256-CBC Encryption & Decryption | `paru -S openssl` |
| **`gpg`** | GPG Key Encryption | `paru -S gnupg` |
| **`tar`** | Archive Packing & Unpacking | `paru -S tar` |
| **`curl`** | GitHub API & Private Vault Sync | `paru -S curl` |
| **`git`** | Repository & Vault Operations | `paru -S git` |

---

## 📁 Repository Structure

```
.
├── cv_harvester_system_prompt.md  # Master system prompt & enterprise ATS screening rules
├── raw_technical_profile.md       # Master unformatted technical knowledge base (Ignored by Git)
├── cv_template.html               # Clean, purged ModernCV layout container template
├── cv_en.html                     # Generated ATS-optimized English resume (Ignored by Git)
├── cv_pl.html                     # Generated ATS-optimized Polish resume (Ignored by Git)
├── cv_en.pdf                      # Generated PDF English resume (Ignored by Git)
├── cv_pl.pdf                      # Generated PDF Polish resume (Ignored by Git)
├── harvest_cv.sh                  # Interactive CLI harvester & encryption runner script
├── harvest_diff.log               # Visual experience diff tracker log (Ignored by Git)
├── man/man1/vltimate-cv-scraper.1 # UNIX man page documentation
├── output/                        # Backup directory for generated profile & resume assets (Ignored by Git)
├── .vltimate_config.env           # Local persistent credentials & cloud sync config (Ignored by Git)
├── .pdf_customization.json        # PDF rendering & theme customization memory (Ignored by Git)
├── .gitignore                     # Git exclusions for encrypted archives & private data
└── README.md                      # Project documentation
```

---

## 🚀 CLI Usage & Options

```text
USAGE:
  ./harvest_cv.sh [OPTIONS]

OPTIONS:
  -h, --help                Show help documentation
  -t, --tailor <FILE|URL>   Tailor summary, keywords, & bullet points to a Job Description
  -p, --pdf                 Force automated headless PDF export (cv_en.pdf / cv_pl.pdf)
  -d, --diff                Generate visual experience diff log (harvest_diff.log)
  -e, --encrypt-mode <TYPE> Set encryption backend: 'aes' (OpenSSL AES-256) or 'gpg'
  --gui                     Open customization GUI in Google Chrome to set themes/RODO options
  -c, --config              Reconfigure GitHub token & private cloud sync options
```

### Examples
```bash
# 1. Standard harvest with PDF export & visual diff tracking
./harvest_cv.sh --pdf --diff

# 2. Tailor resume specifically for a job posting
./harvest_cv.sh --tailor ./job_posting.txt --pdf

# 3. Encrypt archive using GPG key encryption
./harvest_cv.sh --encrypt-mode gpg
```

---

## 📖 UNIX Man Page
To view the manual page:
```bash
man ./man/man1/vltimate-cv-scraper.1
```

---

## 🔐 Security & Privacy Note
Sensitive data, personal contact details, credentials (`.vltimate_config.env`), customization settings (`.pdf_customization.json`), and plain resume files (`raw_technical_profile.md`, `cv_en.html`, `cv_pl.html`, `cv_en.pdf`, `cv_pl.pdf`, `output/`) are strictly excluded from git tracking via `.gitignore`.
