#!/bin/bash

PRIVKEY_PATH="secrets/sparkle_dsa_priv.pem"

cd "$(dirname "$0")/.."

./sparkle_bin/generate_appcast "$PRIVKEY_PATH" "../grabbox_site/updates"
