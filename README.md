# Vltimate CV Scraper

An automated, privacy-conscious resume architecture and technical intelligence harvester built for software engineers, game developers, and systems specialists. Powered by **Antigravity CLI (`agy`)**, **OpenSSL AES-256 encryption**, and **Tailwind CSS single-column ATS layout engine**.

---

## 🌟 Key Features

- **Automated Data Harvesting**: Scans local OS specs, shell command history, git configurations, and remote GitHub profile repositories (`github.com/Vikyek`).
- **Private GitHub Cloud Sync**: Automatically pulls prior encrypted database vaults from a private GitHub repository (`vltimate-cv-vault`), decrypts them as input, and pushes newly updated AES-256 encrypted archives after harvesting.
- **Persistent Configuration Engine**: Remembers your GitHub credentials and sync preferences in `.vltimate_config.env` (strictly protected by `.gitignore`).
- **Enterprise ATS & AI Screener Optimization**: Designed specifically for modern ATS systems (Workday, Greenhouse, Taleo) and AI recruiter scoring platforms (Eightfold AI) using single-column semantic HTML5 and STAR-K structured summary blocks.
- **Robust Dependency Verification**: Automatically verifies required system tools (`openssl`, `tar`, `curl`, `git`, `agy`) before execution.
- **Full Security Cleanup**: Automatically wipes unencrypted plain text profile and generated resume files after encryption to ensure personal data exists ONLY inside the encrypted archive.
- **Bilingual ATS Resumes**: Maintains synchronized English ([`cv_en.html`](cv_en.html)) and Polish ([`cv_pl.html`](cv_pl.html)) interactive resumes with printable A4 paper sheets and responsive fluid views.

---

## ⚙️ System Dependencies

`Vltimate CV Scraper` requires the following system utilities:

| Dependency | Purpose | Installation (Arch Linux / `paru`) |
| :--- | :--- | :--- |
| **`agy`** | Antigravity CLI AI Engine | `npm install -g @google/antigravity-cli` / `agy` |
| **`openssl`** | AES-256-CBC Encryption & Decryption | `paru -S openssl` |
| **`tar`** | Archive Packing & Unpacking | `paru -S tar` |
| **`curl`** | GitHub API & Private Vault Sync | `paru -S curl` |
| **`git`** | Repository & Vault Operations | `paru -S git` |

The `harvest_cv.sh` runner automatically checks for all dependencies on startup and alerts you if any binary is missing.

---

## 📁 Repository Structure

```
.
├── cv_harvester_system_prompt.md  # Master system prompt & enterprise ATS screening rules
├── raw_technical_profile.md       # Master unformatted technical knowledge base (Ignored by Git)
├── cv_template.html               # Clean, purged ModernCV layout container template
├── cv_en.html                     # Generated ATS-optimized English resume (Ignored by Git)
├── cv_pl.html                     # Generated ATS-optimized Polish resume (Ignored by Git)
├── harvest_cv.sh                  # Interactive CLI harvester & encryption runner script
├── output/                        # Backup directory for generated profile & resume assets (Ignored by Git)
├── .vltimate_config.env           # Local persistent credentials & cloud sync config (Ignored by Git)
├── .gitignore                     # Git exclusions for encrypted archives & private data
└── README.md                      # Project documentation
```

---

## 🚀 Usage Instructions

### Running Vltimate CV Scraper
Execute the interactive runner script:
```bash
./harvest_cv.sh
```

The script will automatically:
1. **Verify Dependencies**: Checks for `openssl`, `tar`, `curl`, `git`, and `agy`.
2. **Persistent Configuration & Cloud Sync**: Asks once to set up optional Private GitHub Cloud Sync. If enabled, it connects to your private repository (`vltimate-cv-vault`) and pulls down previous encrypted database archives.
3. **Auto-Detect Encrypted Data**: Checks if an encrypted knowledge archive (`personal_data.tar.gz.enc`) exists. If found, it interactively prompts for the decryption password and unpacks the prior data before harvesting.
4. **Execute Intelligence Harvesting**: Calls `agy` to scan system specs, shell history, git repos, and GitHub API, updating `raw_technical_profile.md`, `cv_en.html`, and `cv_pl.html`.
5. **Interactive Encryption, Cloud Push & Security Cleanup**: Asks if you want to pack and encrypt your personal technical data using a custom passphrase:
   ```text
   Do you want to pack and encrypt the personal results now? (y/N): y
   Enter encryption password: 
   Re-enter encryption password: 
   ```
   Upon encryption, the encrypted archive is auto-pushed to your private GitHub vault, and unencrypted plain text files are wiped from disk for total privacy.

---

## 💡 Recommended Future Improvements & Enhancements

1. **Headless PDF Export Engine**:
   - Integrate automated PDF compilation using `chromium --headless --print-to-pdf` or `puppeteer` inside `harvest_cv.sh` to generate production-ready PDF files (`cv_en.pdf`, `cv_pl.pdf`) alongside HTML.

2. **Job Offer / JD Specific Tailoring**:
   - Add a `--job-offer <url_or_file>` parameter to `harvest_cv.sh`. `agy` will parse the job posting, extract required keywords, and dynamically rank your summary, tag cloud, and project bullet points for that specific position.

3. **Visual Experience Diff Tracker**:
   - Add an automated diff report generator (`harvest_diff.log`) showing what new repositories, kernel parameters, hardware skills, or tools were discovered in the latest run compared to prior versions.

4. **YubiKey / GPG Hardware Key Support**:
   - Provide an optional GPG smartcard / YubiKey hardware key encryption mode alongside OpenSSL symmetric AES-256.

---

## 🔐 Security & Privacy Note
Sensitive data, personal contact details, credentials (`.vltimate_config.env`), and plain resume files (`raw_technical_profile.md`, `cv_en.html`, `cv_pl.html`, `output/`) are strictly excluded from git tracking via `.gitignore`. You can safely commit and share repository template logic without exposing personal ID information.
