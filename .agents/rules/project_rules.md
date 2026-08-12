# Vltimate CV Scraper - Project-Specific Agent Rules

## 1. Console Output Formatting & Path Conventions
- **Relative Paths**: Always format paths in quoted relative syntax (e.g., `'./output/'`, `'./config/vltimate_config.env'`).
- **Clean Console Output**: No ISO timestamps in standard output unless `--verbose` is passed. Timestamps go to log files in `'./logs/'` only.
- **Silent Checkpointing**: Checkpoint saved/cleared status messages are written to `'./logs/'` silently and are only printed to console output when `--verbose` (`-v`) is enabled.
- **No "(gitignored)" annotations**: Never mention gitignore status in console output messages.

## 2. Configuration Directory Structure
- All config files live in `'./config/'` subdir.
- **Default templates** (`config.template.env`, `pdf_customization.template.json`) are tracked in git — NEVER edit templates when changing config values.
- **Actual configs** (`vltimate_config.env`, `pdf_customization.json`, `checkpoint.json`, `conflict_audit.json`) are gitignored.

## 3. Environment Variable Detection & Non-Interactive Bypassing
- Check environment variables (`DECRYPT_PASS`, `ENCRYPT_PASS`, `GH_TOKEN`, `GITHUB_USER`) before prompting.
- If present, log detection and automatically bypass interactive prompts.

## 4. Masked Secret Input
- All password and token inputs show `*` characters for each keystroke so the user knows input is being registered.

## 5. Customization GUI & Re-Use Flow
- If `'./config/pdf_customization.json'` exists, prompt: `🎨 Re-open Chrome HTML GUI to change layout options? [y/N]:` (default: NO).
- Falls back to `'./local_preview/cv.html'` → `'./cv_template.html'` for GUI display.

## 6. Encryption & Default Prompting
- Use standard `[Y/n]` indicator without redundant `(Default: YES)`.
- Interactively prompt for encryption backend if not specified via CLI flag.

## 7. Crash Resilience
- `run_with_spinner` captures exit codes and shows `✘ (Failed)` on error instead of crashing.
- On harvest failure/timeout, offer retry/continue/abort menu.

## 8. Production & Devel Synchronization
- 100% functional parity between `./harvest_cv.sh` and `./devel/harvest_cv.sh`.
- Devel version is always a copy of production with version string suffix `-DEVEL`.

## 9. Intelligence Source Reporting
- During harvesting, agy reports each new intelligence source found.
- Sources are tagged `[NEW]` or `[KNOWN]` relative to past collected intel.

## 10. Intelligence Harvesting & Project Attribution Safeguards
- **Clone vs. Author Filter**: Unmodified third-party clones are excluded from candidate project attribution (ignoring local build outputs/logs/configs). If ownership status is ambiguous, prompt the user during interactive refinement.
- **Transformative Successors**: Distinguish between minor upstream PRs vs. major transformative improvements where candidate work creates a next-step successor tool (e.g., `pkgscan`).
- **Multi-Shell & System Log Mining**: Mine all installed shells (`~/.local/share/fish/fish_history`, `~/.bash_history`, `~/.zsh_history`), `journalctl` logs, and `/var/log/pacman.log`.
- **Token Efficiency & agy Fallback**: Use deterministic heuristics first; invoke `agy` fallback when categorization is ambiguous.

## 11. GitHub Profile & Recursive Cross-Site Link Scraping
- **Profile & README Scraping**: Harvest candidate's GitHub user bio, location, social links, badges, stats, and special profile repository README (`<USERNAME>/<USERNAME>`).
- **Recursive Linked Profile Discovery**: Extract linked external profiles (personal site, LinkedIn, Medium, DEV.to, Hashnode, GitLab, Codeberg, Docker Hub, StackOverflow, Kaggle, npm, PyPI) and recursively scrape candidate-authored technical skills, projects, certifications, and experience while ignoring third-party noise.

## 12. Default Starting Point Sites & Cloud Services Inspection
- **Default Starting Web Endpoints**: GitHub Profile API (`users/<USER>`), Special Profile README (`<USER>/<USER>`), Repositories API (`users/<USER>/repos`), Docker Hub API (`hub.docker.com`), npm Registry (`registry.npmjs.org`), and PyPI (`pypi.org`).
- **Local Cloud CLI Inspection**: GCP (`gcloud config list`, `gcloud projects list`), Azure (`az account show`), AWS (`aws configure list`), and `~/.config/rclone/` (remote cloud storage profiles).

## 13. Knowledge Base Viewer, Manual Targets & Aesthetic CLI Makeover
- **Knowledge Database Flag**: `-k` / `--db` / `--knowledge` opens the synced technical knowledge base (`raw_technical_profile.md`) directly in `micro` (or `less`).
- **Manual Target Flag**: `-a` / `--add-source <TARGET>` allows passing extra scrapable local paths, URLs, or notes.
- **Dynamic Heuristic Search Loop**: `discover_dynamic_sources` probes `$PATH`, `~/.local/bin/`, `~/bin/`, `~/Scripts/`, `/opt/`, `~/.config/`, hidden local git repos, `.md` files, environment variables, systemd journal events, and package manager logs for un-predetermined scrapable places.
- **TrueColor Cyberpunk/Trans ANSI Styling**: Console output features 24-bit TrueColor ANSI color palettes (Cyan `#5BCEFA`, Pink `#F5A9B8`, Magenta `#FF66CC`, Violet `#AA55FF`, Mint `#50FA7B`, Gold `#FFB86C`), UTF-8 box-drawing art, and glowing multicolored animated spinners matching candidate dotfile aesthetic preferences (`hyfetch`).

## 14. Customization Auto-Pickup, Log Viewing & User-Friendly Recovery
- **Trash-Free Customization Auto-Move**: `search_and_move_customization` strictly moves (`mv -f`, NOT `cp`) exported customization files (`pdf_customization*.json`) from `~/Downloads/` (or custom paths/directories) into `./config/pdf_customization.json`, ensuring zero leftover trash files remain in `~/Downloads/`.
- **Interactive Fallback & Retry Menu**: If no exported file is detected upon pressing Enter, the script presents an interactive fallback menu: Option 1 (Retry auto-detection in `~/Downloads/`), Option 2 (Enter custom file or parent directory path with silent search), Option 3 (Proceed with default).
- **Log File Viewing**: Startup log path output is hidden by default; execution logs are viewable via `-l` / `--log` flag.
- **User-Friendly Interrupted Run Recovery**: Recovery prompts use clean human language ("Resume previous session") without displaying internal technical checkpoint strings.
- **Silent Snapshot Archive Logging**: Snapshot archive creation is logged to `./logs/` silently and only printed to console output when `--verbose` (`-v`) is enabled.
