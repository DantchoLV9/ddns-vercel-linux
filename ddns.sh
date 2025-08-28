#!/bin/bash

# CONFIG
TOKEN=""
TEAM_ID=""
DOMAIN=""
SUBDOMAIN=""

# Get current public IP
CURRENT_IP=$(curl -s https://api.ipify.org)

echo "Current IP: $CURRENT_IP"

# Get existing DNS records for the domain
if [ -z "$TEAM_ID" ]; then
  RECORDS=$(curl -s -H "Authorization: Bearer $TOKEN" \
    "https://api.vercel.com/v4/domains/$DOMAIN/records")
else
  RECORDS=$(curl -s -H "Authorization: Bearer $TOKEN" \
    "https://api.vercel.com/v4/domains/$DOMAIN/records?teamId=$TEAM_ID")
fi

# Extract record ID and value for the subdomain (jq required)
RECORD_ID=$(echo "$RECORDS" | jq -r --arg sub "$SUBDOMAIN" '.records[] | select(.type=="A" and .name==$sub) | .id')
RECORD_IP=$(echo "$RECORDS" | jq -r --arg sub "$SUBDOMAIN" '.records[] | select(.type=="A" and .name==$sub) | .value')

if [ "$RECORD_IP" == "$CURRENT_IP" ]; then
  echo "DNS already up to date ($SUBDOMAIN.$DOMAIN -> $CURRENT_IP)"
  exit 0
fi

if [ -n "$RECORD_ID" ]; then
  echo "Updating record $RECORD_ID..."
  curl -s -X PATCH \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.vercel.com/v1/domains/records/$RECORD_ID?teamId=$TEAM_ID" \
    -d '{
      "value": "'"$CURRENT_IP"'"
    }'
else
  echo "Creating new record..."
  curl -s -X POST \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    "https://api.vercel.com/v1/domains/records?teamId=$TEAM_ID" \
    -d '{
      "type": "A",
      "name": "'"$SUBDOMAIN"'",
      "value": "'"$CURRENT_IP"'",
      "ttl": 60
    }'
fi
