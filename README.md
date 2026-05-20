# Python Environment Bootstrap (Multi-Version + Automation)

This toolkit sets up shared Python virtual environments for multiple Python versions and integrates them into user virtualenvs using `virtualenvwrapper`.

> **Platform**: tested on macOS with Homebrew. Linux should work with minor path adjustments; Docker and Ansible stubs exist but are untested.

## Features
- Shared `baseenv` per Python version (e.g., 3.14)
- CLI tool exposure via `PATH`
- Global hooks for seamless integration upon virtual environment creation with `virtualenvwrapper`

## How It Works

The system creates shared base environments (`baseenv-X.Y`) that contain commonly-used packages. The default set installed by `baseenv_setup.sh` is:

| Package | Purpose | Since |
|---|---|---|
| pandas | data analysis | all |
| netCDF4 | NetCDF file I/O | all |
| h5py | HDF5 file I/O | all |
| eccodes | ECMWF GRIB/BUFR file I/O | all |
| jupyter | interactive notebooks | all |
| packaging, iniconfig, pluggy | build/test infrastructure | all |
| astropy | astronomy / time / coordinates | 3.14+ |
| pyarrow | Arrow / Parquet columnar I/O | 3.14+ |
| sqlalchemy | SQL toolkit and ORM | 3.14+ |
| psycopg2 | PostgreSQL adapter | 3.14+ |

Edit the `pip install` line in `baseenv_setup.sh` to customise this list for your site. These packages are automatically available in all user-created virtualenvs through `.pth` linking.

### Architecture

**Core Components:**

1. **baseenv-X.Y** (`/opt/python/virtualenvs/baseenv-X.Y/`): Shared virtual environment per Python version containing common packages. Created with `--system-site-packages` flag and made world-readable.

2. **virtualenvwrapper hooks**: Three bash scripts that automate baseenv integration:
   - `postmkvirtualenv`: Runs after creating new virtualenv, installs pytest and links baseenv packages
   - `postactivate`: Runs when activating any virtualenv, adds baseenv CLI tools to PATH
   - `predeactivate`: Runs before deactivating, cleans up PATH and environment variables

3. **bootstrap_virtualenv.sh**: Creates a `.pth` file in the virtualenv's site-packages that points to baseenv's site-packages, making all baseenv packages importable

### Workflow

When you run `mkvirtualenv myproject`:
1. Standard virtualenv is created
2. `postmkvirtualenv` hook executes automatically
3. `bootstrap_virtualenv.sh` detects Python version (e.g., 3.14)
4. Creates `baseenv_link.pth` pointing to `/opt/python/virtualenvs/baseenv-3.14/lib/python3.14/site-packages`
5. All baseenv packages become available in your `myproject` virtualenv
6. When activated, baseenv CLI tools (jupyter, ipython, etc.) are added to PATH

## Setup
1. Clone the repo anywhere you like:
   ```bash
   git clone <repo-url> ~/Src/python/python-env-bootstrap
   ```

2. Install Python 3.14 (e.g. via `brew install python@3.14`) and create the base environment:
   ```bash
   sudo ./baseenv_setup.sh 3.14
   ```

3. Set up hooks (copy all four files — `bootstrap_virtualenv.sh` must live in
   `$WORKON_HOME` alongside the other hooks):
   ```bash
   cp postactivate predeactivate postmkvirtualenv bootstrap_virtualenv.sh ${WORKON_HOME}
   chmod +x ${WORKON_HOME}/*
   ```

From then on, virtual environments created with `mkvirtualenv` will include the packages in the `baseenv`, and the PATH inside the virtual environment will also be updated to allow the use of CLI tools in `baseenv`.

## Usage

### Creating a New Virtual Environment

After setup is complete, create virtualenvs as usual with `virtualenvwrapper`:

```bash
mkvirtualenv myproject
```

The new environment will automatically:
- Include all packages from the matching baseenv
- Have access to baseenv CLI tools (jupyter, ipython, pytest, etc.)
- Still allow you to install additional packages specific to your project

### Using the Virtual Environment

```bash
# Activate your environment
workon myproject

# All baseenv packages are available
python -c "import pandas; print(pandas.__version__)"

# CLI tools from baseenv are in your PATH
jupyter notebook

# Install project-specific packages
pip install requests flask

# Deactivate when done
deactivate
```

### Verifying baseenv Integration

To check if baseenv is properly linked to your virtualenv:

```bash
workon myproject
python -c "import sys; print([p for p in sys.path if 'baseenv' in p])"
```

You should see the baseenv site-packages path listed.

## Managing baseenv Packages

### Adding or Updating Packages in baseenv

To modify the shared baseenv (requires sudo or appropriate permissions):

```bash
# Activate the baseenv directly
source /opt/python/virtualenvs/baseenv-3.14/bin/activate

# Install or update packages
pip install <new-package>
pip install --upgrade <existing-package>

# Save the updated requirements
pip freeze > /opt/python/virtualenvs/baseenv-3.14/baseenv_requirements.txt

# Ensure permissions are correct (world-readable)
chmod -R a+rx /opt/python/virtualenvs/baseenv-3.14

# Deactivate
deactivate
```

All existing and new virtualenvs will immediately have access to the updated packages.

> **macOS/Homebrew note**: Some C extensions that link against OpenSSL (e.g. `psycopg2`, `cryptography`) will fail with `ld: library 'ssl' not found` because Homebrew's OpenSSL is not on the system linker path. Pass the paths explicitly:
> ```bash
> LDFLAGS="-L/opt/brew/opt/openssl@3/lib" CPPFLAGS="-I/opt/brew/opt/openssl@3/include" pip install psycopg2
> ```

### Creating baseenv for Additional Python Versions

To support a new Python version:

```bash
# Install the Python version first (e.g., via pyenv, apt, brew, etc.)
# Then create its baseenv:
sudo ./baseenv_setup.sh 3.14
```

## Important Notes

- **Python Version Detection**: All scripts automatically detect the Python version to ensure the correct baseenv is linked.

- **Permissions**: The baseenv directories are made world-readable and world-writable (`a+rx`) so all users on the system can access and update the shared packages. This is intentional — it allows the baseenv to be updated over time without `sudo`. If you want to lock the baseenv against accidental changes you can run `sudo chmod -R a-w /opt/python/virtualenvs/baseenv-X.Y` after setup, but you will then need elevated privileges to install or upgrade packages in it.

- **Shell prompt**: `postactivate` customises `PS1` to show the active virtualenv and current git branch. The git branch display uses `__git_ps1` from `git-sh-prompt`. If that is not sourced in your shell, it is silently skipped — the virtualenv name still appears in the prompt.

- **R Integration**: The hooks also configure R library paths (`R_LIBS`) for virtualenvs that use R packages. The directory `$VIRTUAL_ENV/lib/R/library` is created automatically on first activation.

- **Isolation**: While baseenv packages are available, you can still override them by installing different versions in your project virtualenv. Project-specific packages take precedence.

## Other Integrations

Stubs for Docker (`Dockerfile`), Ansible (`ansible/bootstrap.yml`), and GitHub Actions (`.github/workflows/`) exist in the repo but have not been tested. Contributions welcome.
