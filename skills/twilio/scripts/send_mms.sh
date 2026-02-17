#!/bin/bash
# Send MMS (SMS with media) via Twilio

set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 <to-number> <message> <media-url>[,media-url2,...]"
    echo ""
    echo "Examples:"
    echo "  $0 '+15551234567' 'Check this out!' 'https://example.com/image.jpg'"
    echo "  $0 '+15551234567' 'Multiple' 'https://example.com/img1.jpg,https://example.com/img2.jpg'"
    exit 1
fi

TO="$1"
MESSAGE="$2"
MEDIA="$3"

# Check required environment variables
if [ -z "$TWILIO_ACCOUNT_SID" ] || [ -z "$TWILIO_AUTH_TOKEN" ] || [ -z "$TWILIO_PHONE_NUMBER" ]; then
    echo "Error: Required environment variables not set"
    echo "Please set:"
    echo "  TWILIO_ACCOUNT_SID"
    echo "  TWILIO_AUTH_TOKEN"
    echo "  TWILIO_PHONE_NUMBER"
    exit 1
fi

# Build curl command with media URLs
CURL_CMD="curl -s -X POST https://api.twilio.com/2010-04-01/Accounts/$TWILIO_ACCOUNT_SID/Messages.json \
    -u $TWILIO_ACCOUNT_SID:$TWILIO_AUTH_TOKEN \
    --data-urlencode 'From=$TWILIO_PHONE_NUMBER' \
    --data-urlencode 'To=$TO' \
    --data-urlencode 'Body=$MESSAGE'"

# Process media URLs (comma-separated)
IFS=',' read -ra MEDIA_ARRAY <<< "$MEDIA"
for MEDIA_URL in "${MEDIA_ARRAY[@]}"; do
    if [[ ! "$MEDIA_URL" =~ ^https?:// ]]; then
        echo "Error: Media must be publicly accessible URLs (http:// or https://)"
        echo "Got: $MEDIA_URL"
        exit 1
    fi
    CURL_CMD="$CURL_CMD --data-urlencode 'MediaUrl=$MEDIA_URL'"
done

# Send MMS via Twilio API
RESPONSE=$(eval "$CURL_CMD")

# Check for errors
if echo "$RESPONSE" | grep -q '"error_code"'; then
    echo "❌ Error sending MMS:"
    echo "$RESPONSE"
    exit 1
fi

# Success
echo "✓ MMS sent successfully"
echo "  From: $TWILIO_PHONE_NUMBER"
echo "  To: $TO"
echo "  Media: ${#MEDIA_ARRAY[@]} attachment(s)"
echo "  Response: $RESPONSE"
