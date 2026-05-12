# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This toolkit creates shared Python virtual environments (`baseenv`) for multiple Python versions and integrates them into user virtualenvs via `virtualenvwrapper` hooks. The key concept is that shared base environments contain commonly-used packages (pandas, netCDF4, h5py, jupyter, etc.) that are automatically available in all user-created virtualenvs through `.pth` linking.

## Architecture

### Core Components

1. **baseenv-X.Y** (`/opt/python/virtualenvs/baseenv-X.Y/`): Shared virtual environment per Python version containing common packages. Created with `--system-site-packages` flag and made world-readable (`a+rx`). Write-protection (`a-w`) is intentionally left off so the baseenv can be updated without elevated privileges over time.

2. **virtualenvwrapper hooks**: Three bash scripts that automate baseenv integration:
   - `postmkvirtualenv`: Runs after creating new virtualenv. Installs pytest and calls `bootstrap_virtualenv.sh` to link baseenv packages
   - `postactivate`: Runs when activating any virtualenv. Adds baseenv CLI tools to PATH and sets up R library path
   - `predeactivate`: Runs before deactivating. Cleans up PATH and unsets R_LIBS

3. **bootstrap_virtualenv.sh**: Creates a `.pth` file in the virtualenv's site-packages that points to baseenv's site-packages, making all baseenv packages importable

### How It Works

When a user runs `mkvirtualenv myproject`:
1. Standard virtualenv is created
2. `postmkvirtualenv` hook executes
3. `bootstrap_virtualenv.sh` detects Python version (e.g., 3.13)
4. Creates `baseenv_link.pth` pointing to `/opt/python/virtualenvs/baseenv-3.13/lib/python3.13/site-packages`
5. All baseenv packages become available in `myproject` virtualenv
6. When activated, baseenv CLI tools (jupyter, etc.) are added to PATH

## Commands

### Initial Setup

Create a baseenv for a Python version (requires sudo):
```bash
sudo ./baseenv_setup.sh 3.13
```

Install virtualenvwrapper hooks (one-time setup). All four files must land in `$WORKON_HOME` — `postmkvirtualenv` calls `$WORKON_HOME/bootstrap_virtualenv.sh` directly:
```bash
cp postactivate predeactivate postmkvirtualenv bootstrap_virtualenv.sh ${WORKON_HOME}
chmod +x ${WORKON_HOME}/*
```

### Modifying baseenv Packages

To add/update packages in the baseenv:
```bash
source /opt/python/virtualenvs/baseenv-3.13/bin/activate
pip install <new-package>
pip freeze > /opt/python/virtualenvs/baseenv-3.13/baseenv_requirements.txt
chmod -R a+rx /opt/python/virtualenvs/baseenv-3.13
```

Note: The baseenv directory is made world-readable so all users can access it.

## Important Notes

- Hook paths: `postmkvirtualenv` calls `$WORKON_HOME/bootstrap_virtualenv.sh`. The repo clone location is irrelevant as long as all four files are copied to `$WORKON_HOME` during installation.
- Python version detection: All scripts dynamically detect the Python version using `sys.version_info` to ensure correct baseenv matching.
- R integration: The hooks also set up R library paths (`R_LIBS`) for virtualenvs that use R packages.
