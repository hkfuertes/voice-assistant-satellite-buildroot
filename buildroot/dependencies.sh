#!/bin/bash
set -e

apt-get update && apt-get install -y \
    build-essential \
    git \
    wget \
    cpio \
    unzip \
    rsync \
    bc \
    libncurses5-dev \
    file \
    python3 \
    python-is-python3 \
    vim \
    sudo \
    && rm -rf /var/lib/apt/lists/*
