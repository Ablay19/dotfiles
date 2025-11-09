#!/usr/bin/env bash
set -e

CFG="$HOME/.config/gapi"
mkdir -p "$CFG"
CREDS="$CFG/credentials.json"
TOKEN="$CFG/token.json"

CLIENT_ID=$(jq -r .installed.client_id "$CREDS")
CLIENT_SECRET=$(jq -r .installed.client_secret "$CREDS")
SCOPES="https://www.googleapis.com/auth/spreadsheets https://www.googleapis.com/auth/drive.file"

AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth?response_type=code&client_id=${CLIENT_ID}&redirect_uri=http://localhost&scope=$(jq -rn --arg s "$SCOPES" '$s|@uri')&access_type=offline&prompt=consent"

echo "1) افتح هذا الرابط في المتصفح على هاتفك:"
echo "$AUTH_URL"
echo
read -p "2) أدخل الكود (code) الذي حصلت عليه من إعادة التوجيه: " CODE

# استبدال الكود برابط التبادل
RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
  -d client_id="$CLIENT_ID" \
  -d client_secret="$CLIENT_SECRET" \
  -d code="$CODE" \
  -d grant_type=authorization_code \
  -d redirect_uri="http://localhost")

echo "$RESPONSE" | jq '.' > "$TOKEN"
echo "token saved to $TOKEN"
