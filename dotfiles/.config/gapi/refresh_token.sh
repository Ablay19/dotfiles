#!/usr/bin/env bash
set -e
CFG="$HOME/.config/gapi"
CREDS="$CFG/credentials.json"
TOKEN="$CFG/token.json"

REFRESH_TOKEN=$(jq -r .refresh_token "$TOKEN")
CLIENT_ID=$(jq -r .installed.client_id "$CREDS")
CLIENT_SECRET=$(jq -r .installed.client_secret "$CREDS")

RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d client_id="$CLIENT_ID" \
  -d client_secret="$CLIENT_SECRET" \
  -d refresh_token="$REFRESH_TOKEN" \
  -d grant_type=refresh_token)

# ادمج النتائج (access_token + expiry) مع refresh_token القديم
jq -s '.[0] * .[1]' <(echo "$RESPONSE") "$TOKEN" > "$TOKEN.tmp" && mv "$TOKEN.tmp" "$TOKEN"
echo "token refreshed"
