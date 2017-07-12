#!/bin/bash

PRIVKEY_PATH="secrets/sparkle_dsa_priv.pem"

cd "$(dirname "$0")/.."

latest="$(basename "$(ls -1t "site/updates/"*.zip | head -n1)")"

./sparkle_bin/generate_appcast "$PRIVKEY_PATH" "site/updates"

sed "s#%latest_zip%#updates/$latest#" site/index.tpl >site/index.html
