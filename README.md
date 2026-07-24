## Developer Security Setup (One-Time Setup)

To prevent accidental leaks of API keys or secrets, this repository uses **Gitleaks** with shared pre-commit hooks.

### 1. Install Gitleaks
Make sure `gitleaks` is installed on your system:
* **Mac (Homebrew):** `brew install gitleaks`
* **Windows (Winget):** `winget install gitleaks`
* **Linux:** `sudo snap install gitleaks`

### 2. Enable Shared Git Hooks
After cloning the repository, run this command in your terminal **once** to enable local security checks:

```bash
git config core.hooksPath .githooks