# Vltimate CV Scraper

An automated, privacy-conscious resume architecture and technical intelligence harvester built for software engineers, game developers, and systems specialists. Powered by **Antigravity CLI (`agy`)**, **OpenSSL AES-256 encryption**, and **Tailwind CSS single-column ATS layout engine**.

---

## 🌟 Key Features

- **Automated Data Harvesting**: Scans local OS specs, shell command history, git configurations, and remote GitHub profile repositories (`github.com/Vikyek`).
- **Enterprise ATS & AI Screener Optimization**: Designed specifically for modern ATS systems (Workday, Greenhouse, Taleo) and AI recruiter scoring platforms (Eightfold AI) using single-column semantic HTML5 and STAR-K structured summary blocks.
- **Robust Dependency Verification**: Automatically verifies required system tools (`openssl`, `tar`, `curl`, `git`, `agy`) before execution.
- **Interactive Encryption & Decryption**: Supports auto-detecting packed/encrypted archives (`personal_data.tar.gz.enc`), interactive password prompts, and AES-256-CBC encryption for personal profiles.
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
| **`curl`** | GitHub API Scraping | `paru -S curl` |
| **`git`** | Repository & Remote Verification | `paru -S git` |

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
2. **Auto-Detect Encrypted Data**: Checks if an encrypted knowledge archive (`personal_data.tar.gz.enc`) exists. If found, it interactively prompts for the decryption password and unpacks the prior data before harvesting.
3. **Execute Intelligence Harvesting**: Calls `agy` to scan system specs, shell history, git repos, and GitHub API, updating `raw_technical_profile.md`, `cv_en.html`, and `cv_pl.html`.
4. **Interactive Encryption & Security Cleanup**: Asks if you want to pack and encrypt your personal technical data using a custom passphrase:
   ```text
   Do you want to pack and encrypt the personal results now? (y/N): y
   Enter encryption password: 
   Re-enter encryption password: 
   ```
   Upon encryption, unencrypted plain text files are wiped from disk for total privacy.

---

## 🔐 Security & Privacy Note
Sensitive data, personal contact details, and plain resume files (`raw_technical_profile.md`, `cv_en.html`, `cv_pl.html`, `output/`) are excluded from git tracking via `.gitignore`. You can safely commit and share repository template logic without exposing personal ID information.
