#!/bin/bash
set -euo pipefail
shopt -s nullglob

API_KEY="edd1c9f034335f136f87ad84b625c8f1"
APISIX_API="http://127.0.0.1:9180/apisix/admin/ssls"
CERT_DIR="/etc/apisix/ssl"

# Debug: show existing SSL entries
echo "Checking existing SSL entries in APISIX..."
curl -s "$APISIX_API" -H "X-API-KEY: $API_KEY" | jq .

# Get last ID (adjust jq filter if needed)
LAST_ID=$(curl -s "$APISIX_API" -H "X-API-KEY: $API_KEY" | jq '.list[].value.id' | sort -n | tail -1)
if [ -z "$LAST_ID" ]; then
  LAST_ID=0
fi
NEW_ID=$((LAST_ID + 1))

# Loop over certs
for CERT in "$CERT_DIR"/*.pem "$CERT_DIR"/*.crt; do
  BASENAME=$(basename "$CERT")
  NAME="${BASENAME%.*}"
  KEY="$CERT_DIR/$NAME.key"

  if [ ! -f "$KEY" ]; then
    echo "⚠️  Key file for $CERT not found, skipping..."
    continue
  fi

  TMP_JSON="/tmp/ssl_${NAME}.json"

  # Prepare JSON for APISIX upload
  cat > "$TMP_JSON" <<EOF
{
  "cert": "$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "$CERT")",
  "key": "$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "$KEY")",
  "snis": ["$NAME","*.$NAME"]
}
EOF

  # Upload SSL to APISIX
  echo "➡️ Uploading SSL for $NAME with ID=$NEW_ID"
  RESP=$(curl -s -o /dev/null -w "%{http_code}" \
    "$APISIX_API/$NEW_ID" \
    -H "X-API-KEY: $API_KEY" \
    -X PUT -d @"$TMP_JSON")

  if [ "$RESP" -eq 200 ] || [ "$RESP" -eq 201 ]; then
    echo "✅ Uploaded $NAME (ID=$NEW_ID)"
  else
    echo "❌ Failed to upload $NAME (HTTP $RESP)"
    NEW_ID=$((NEW_ID + 1))
    continue
  fi

  # Display expiration dates
  echo "⏰ Certificate expiration for $NAME:"
  openssl x509 -in "$CERT" -noout -text | grep -E "Not (Before|After)"
  echo "---------------------------------------"

  NEW_ID=$((NEW_ID + 1))
done
