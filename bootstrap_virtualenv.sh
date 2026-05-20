#!/bin/bash

VENV_PATH="$VIRTUAL_ENV"
if [ -z "$VENV_PATH" ]; then
    echo "Not inside a virtualenv — exiting."
    exit 1
fi

PYTHON_VERSION=$("$VENV_PATH"/bin/python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
BASEENV="/opt/python/virtualenvs/baseenv-${PYTHON_VERSION}"
SITEPKG="${BASEENV}/lib/python${PYTHON_VERSION}/site-packages"

if [ -d "$SITEPKG" ]; then
    echo "$SITEPKG" > "$VENV_PATH/lib/python${PYTHON_VERSION}/site-packages/baseenv_link.pth"
    echo "Linked baseenv-${PYTHON_VERSION} Python packages."
else
    echo "WARNING: baseenv not found for Python $PYTHON_VERSION"
fi
