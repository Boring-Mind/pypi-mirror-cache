# syntax = docker/dockerfile:1.3

# Please, set up Docker BuildKit to use this Dockerfile
# Instruction how to set up BuildKit is here:
# https://docs.docker.com/build/buildkit/#getting-started

FROM python:3.11.5-slim-bookworm AS base

ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    # Disable check for pip updates on running every pip command.
    # Provides a little speedup when running pip commands
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    # Increase pip timeout to prevent issues with python packages download
    PIP_DEFAULT_TIMEOUT=100 \
    POETRY_HOME="/opt/poetry" \
    POETRY_CACHE_DIR="~/.cache/pypoetry" \
    POETRY_VIRTUALENVS_IN_PROJECT=true \
    POETRY_NO_INTERACTION=1 \
    PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv"

ENV PATH="$POETRY_HOME/bin:$VENV_PATH/bin:$PATH"

RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        build-essential \
        # Is needed for Gunicorn grace reload script
        procps \
    && apt-get clean

# Install Poetry - respects $POETRY_VERSION & $POETRY_HOME
ENV POETRY_VERSION=1.6.1
RUN curl -sSL https://install.python-poetry.org | python3 -

RUN mkdir $PYSETUP_PATH

# We copy our Python requirements here to cache them
# and install only runtime deps using poetry
COPY pyproject.toml ./poetry.lock* $PYSETUP_PATH

# Install python dependencies
WORKDIR $PYSETUP_PATH
RUN --mount=type=cache,target=/root/.cache/pypoetry \
    poetry install --no-root

# 'development' stage installs all dev deps and can be used to develop code.
# For example, using docker-compose to mount local volume under /app
FROM python:3.11.5-alpine3.18 AS development

ENV PYSETUP_PATH="/opt/pysetup" \
    VENV_PATH="/opt/pysetup/.venv" \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

ENV PATH="$VENV_PATH/bin:$PATH"

# Install bash for entrypoint script
RUN apk add --no-cache bash

# Update python packages to the latest versions
RUN pip install -U pip wheel setuptools

# Copying poetry and venv into image
RUN mkdir -p $PYSETUP_PATH
COPY --from=base $PYSETUP_PATH $PYSETUP_PATH

# Copying in our entrypoint
COPY --chmod=744 ./devops/backend-entrypoint.sh /app/backend-entrypoint.sh

WORKDIR /app
COPY ./app .

ENTRYPOINT ./backend-entrypoint.sh
