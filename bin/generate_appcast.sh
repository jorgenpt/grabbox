#!/bin/bash

PRIVKEY_PATH="bin/sparkle_dsa_priv.pem"

cd "$(dirname "$0")/.."

git subtree pull --prefix=pages origin gh-pages
./sparkle_bin/generate_appcast "$PRIVKEY_PATH" "docs/updates"
