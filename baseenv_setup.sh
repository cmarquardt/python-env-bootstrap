#!/bin/bash

PYTHON_VERSION=$1

if [ -z "$PYTHON_VERSION" ]; then
    echo "Usage: $0 <python_version> (e.g. 3.10)"
    exit 1
fi

PYTHON_PATH=$(which "python$PYTHON_VERSION")
if [ -z "$PYTHON_PATH" ]; then
    echo "Python $PYTHON_VERSION not found"
    exit 1
fi

BASEENV_DIR="/opt/python/virtualenvs/baseenv-${PYTHON_VERSION}"

echo "Creating base environment at $BASEENV_DIR using $PYTHON_PATH"
virtualenv --python="$PYTHON_PATH" --system-site-packages "$BASEENV_DIR"

# shellcheck source=/dev/null
source "$BASEENV_DIR/bin/activate"
pip install --upgrade pip
#pip install numpy pandas scipy matplotlib pillow netCDF4 h5py jupyter
# --ignore-installed ensures all packages and their transitive dependencies land
# in the baseenv's own site-packages.  Without this, pip may satisfy deps from
# the system site-packages (visible here via --system-site-packages) and skip
# installing them locally, making them invisible to user virtualenvs that link
# to the baseenv via a .pth file.
pip install --ignore-installed packaging iniconfig pluggy pandas netCDF4 h5py eccodes jupyter \
    astropy pyarrow sqlalchemy
# psycopg2 needs pg_config (from libpq) and links against OpenSSL.  Both are
# keg-only on Homebrew and not on the default PATH / linker search path.
OPENSSL_PREFIX=$(brew --prefix openssl@3 2>/dev/null || true)
LIBPQ_PREFIX=$(brew --prefix libpq 2>/dev/null || true)
if [ -n "$LIBPQ_PREFIX" ]; then
    export PATH="${LIBPQ_PREFIX}/bin:$PATH"
fi
if [ -n "$OPENSSL_PREFIX" ]; then
    LDFLAGS="-L${OPENSSL_PREFIX}/lib" CPPFLAGS="-I${OPENSSL_PREFIX}/include" \
        pip install --ignore-installed psycopg2
else
    pip install --ignore-installed psycopg2
fi
pip freeze > "$BASEENV_DIR/baseenv_requirements.txt"

#chmod -R a-w "$BASEENV_DIR"
chmod -R a+rx "$BASEENV_DIR"

echo "Base environment setup for Python $PYTHON_VERSION complete."
