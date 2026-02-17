#!/bin/bash
# Send SMS via Twilio

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <to-number> <message>"
    echo "Example: $0 '+15551234567' 'Hello from OpenClaw!'"
    exit 1
fi

TO="$1"
MESSAGE="$2"

# Check required environment variables
if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_AUTH_TOKEN" ] || [ -z "$TWILIO_PHONE_NUMBER" ]; then
    echo "Error: Required environment variables not set"
    echo "Please set:"
    echo "  TWILIO_ACCOUNT_SID"
    echo "  TWILIO_AUTH_TOKEN"
    echo "  TWILIO_PHONE_NUMBER"
    exit 1
fi

# Send SMS via Twilio API
RESPONSE=$(curl -s -X POST "https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json" \
    -u "$TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN" \
    --data-urlencode "From=$TWILIO_PHONE_NUMBER" \
    --data-urlencode "To=$TO" \
    --data-urlencode "Body=$MESSAGE")

# Check for errors (simple grep-based check)
if echo "$RESPONSE" | grep -q '"error_code"'; then
    echo "❌ Error sending SMS:"
    echo "$RESPONSE"
    exit 1
fi

# Success
echo "✓ SMS sent successfully"
echo "  From: $TWILIO_PHONE_NUMBER"
echo "  To: $TO"
echo "  Response: $RESPONSE"
