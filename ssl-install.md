,,,
cat > ssl.json <<EOF                                                                                                        
{
  "cert": "$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' apsissolutions.pem)",
  "key": "$(awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' apsissolutions.com.key)",
  "snis": ["apsissolutions.com","*.apsissolutions.com"]
}
EOF
,,,
## installation of SSL
curl http://127.0.0.1:9180/apisix/admin/ssls/2 \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -X PUT -d @/tmp/ssl.json
