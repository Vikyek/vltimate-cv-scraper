# Technical Intelligence Harvester & ATS CV Generator

An automated, privacy-conscious resume architecture and technical data harvester built for software engineers, game developers, and systems specialists. Powered by **Antigravity CLI (`agy`)**, **OpenSSL AES-256 encryption**, and **Tailwind CSS single-column ATS layout engine**.

---

## 🌟 Key Features

- **Automated Data Harvesting**: Scans local OS specs, shell command history, git configurations, and remote GitHub profile repositories (`github.com/Vikyek`).
- **Enterprise ATS & AI Screener Optimization**: Designed specifically for modern ATS systems (Workday, Greenhouse, Taleo) and AI recruiter scoring platforms (Eightfold AI) using single-column semantic HTML5 and STAR-K structured summary blocks.
- **Interactive Encryption & Decryption**: Supports auto-detecting packed/encrypted archives (`personal_data.tar.gz.enc`), interactive password prompts, and AES-256-CBC encryption for personal profiles.
- **Bilingual ATS Resumes**: Maintains synchronized English ([`cv_en.html`](cv_en.html)) and Polish ([`cv_pl.html`](cv_pl.html)) interactive resumes with printable A4 paper sheets and responsive fluid views.

---

## 📁 Repository Structure

```
.
├── cv_harvester_system_prompt.md  # Master system prompt & enterprise ATS screening rules
├── raw_technical_profile.md       # Master unformatted technical knowledge base
├── cv_template.html               # Clean, purged ModernCV layout container template
├── cv_en.html                     # Generated ATS-optimized English resume
├── cv_pl.html                     # Generated ATS-optimized Polish resume
├── harvest_cv.sh                  # Interactive CLI harvester & encryption runner script
├── output/                        # Backup directory for generated profile & resume assets
├── .gitignore                     # Git exclusions for encrypted archives & private data
└── README.md                      # Project documentation
```

---

## 🚀 Usage Instructions

### 1. Running the Automated Harvester & Resume Generator
Execute the interactive runner script:
```bash
./harvest_cv.sh
```

The script will automatically:
1. **Auto-Detect Encrypted Data**: Checks if an encrypted knowledge archive (`personal_data.tar.gz.enc`) exists. If found, it interactively prompts for the decryption password and unpacks the prior data before harvesting.
2. **Execute Intelligence Harvesting**: Calls `agy` to scan system specs, shell history, git repos, and GitHub API, updating `raw_technical_profile.md`, `cv_en.html`, and `cv_pl.html`.
3. **Interactive Encryption Prompt**: Asks if you want to pack and encrypt your personal technical data using a custom passphrase:
   ```text
   Do you want to pack and encrypt the personal results? (y/N): y
   Enter encryption password: 
   Re-enter encryption password: 
   ```

---

## 🔐 Security & Privacy Note
Sensitive data, personal contact details, and encrypted archives (`*.tar.gz.enc`, `*.enc`, `*.gpg`) are excluded from git tracking via `.gitignore`. You can safely commit and share repository template logic without exposing personal ID information.
