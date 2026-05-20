#!/bin/bash

PYTHON_VERSION=$1

if [ -z "$PYTHON_VERSION" ]; then
    echo "Usage: $0 <python_version> (e.g. 3.10)"
    exit 1
fi

PYTHON_PATH=$(which python$PYTHON_VERSION)
if [ -z "$PYTHON_PATH" ]; then
    echo "Python $PYTHON_VERSION not found"
    exit 1
fi

BASEENV_DIR="/opt/python/virtualenvs/baseenv-${PYTHON_VERSION}"

echo "Creating base environment at $BASEENV_DIR using $PYTHON_PATH"
virtualenv --python="$PYTHON_PATH" --system-site-packages "$BASEENV_DIR"

source "$BASEENV_DIR/bin/activate"
pip install --upgrade pip
#pip install numpy pandas scipy matplotlib pillow netCDF4 h5py jupyter 
pip install packaging iniconfig pluggy pandas netCDF4 h5py eccodes jupyter \
    astropy pyarrow sqlalchemy
# psycopg2 links against OpenSSL; on macOS/Homebrew libssl is not on the
# default linker path so we pass it explicitly (harmless no-op on Linux).
LDFLAGS="-L/opt/brew/opt/openssl@3/lib" CPPFLAGS="-I/opt/brew/opt/openssl@3/include" \
    pip install psycopg2
pip freeze > "$BASEENV_DIR/baseenv_requirements.txt"

#chmod -R a-w "$BASEENV_DIR"
chmod -R a+rx "$BASEENV_DIR"

echo "Base environment setup for Python $PYTHON_VERSION complete."
