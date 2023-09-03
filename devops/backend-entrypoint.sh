#!/bin/bash

set -e

# activate our virtual environment
source "$VENV_PATH"/bin/activate;

# Run hypercorn server
hypercorn main:app;

# Evaluating passed command:
#exec "$@"

