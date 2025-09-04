#!/bin/bash

API_KEY="edd1c9f034335f136f87ad84b625c8f1"
APISIX_API="http://127.0.0.1:9180/apisix/admin/ssls"
CERT_DIR="/etc/ssl"

# Get the highest existing ID in APISIX
LAST_ID=$(curl -s "$APISIX_API" -H "X-API-KEY: $API_KEY" | jq '.list[].id' | sort -n | tail -1)
if [ -z "$LAST_ID" ]; then
  LAST_ID=0
fi

NEW_ID=$((LAST_ID + 1))

# Loop over all cert files
for CERT in "$CERT_DIR"/*.{crt,pem}; do
  [ -f "$CERT" ] || continue  # skip if no file

  BASENAME=$(basename "$CERT")
  NAME="${BASENAME%.*}"

  KEY="$CERT_DIR/$NAME.key"
  if [ ! -f "$KEY" ]; then
    echo "⚠️  Key file for $CERT not found, skipping..."
    continue
  fi

  TMP_JSON="/tmp/ssl_${NAME}.json"

  cat > "$TMP_JSON" <<EOF
{
  "cert": "$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "$CERT")",
  "key": "$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' "$KEY")",
  "snis": ["$NAME","*.$NAME"]
}
EOF

  echo "➡️ Uploading SSL for $NAME with ID=$NEW_ID"
  RESP=$(curl -s -o /dev/null -w "%{http_code}" \
    "$APISIX_API/$NEW_ID" \
    -H "X-API-KEY: $API_KEY" \
    -X PUT -d @"$TMP_JSON")

  if [ "$RESP" -eq 200 ] || [ "$RESP" -eq 201 ]; then
    echo "✅ Uploaded $NAME (ID=$NEW_ID)"
  else
    echo "❌ Failed to upload $NAME (HTTP $RESP)"
  fi

  NEW_ID=$((NEW_ID + 1))

done
