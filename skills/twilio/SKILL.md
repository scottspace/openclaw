---
name: twilio
description: Send and receive SMS/MMS messages via Twilio with support for text, images, videos, and media attachments. Use for bidirectional SMS communication, unified cross-channel context (SMS + Discord/other channels), sending alerts/notifications via text, or multimedia messaging.
homepage: https://www.twilio.com
metadata:
  {
    "openclaw":
      {
        "emoji": "📱",
        "requires": 
          {
            "bins": ["curl"],
            "env": ["TWILIO_ACCOUNT_SID", "TWILIO_AUTH_TOKEN", "TWILIO_PHONE_NUMBER"]
          }
      }
  }
---

# Twilio SMS/MMS

Send and receive text messages and multimedia content via Twilio.

## Overview

This skill enables:
- **Outbound SMS** - Send text messages to phone numbers
- **Outbound MMS** - Send images, videos, PDFs with messages
- **Inbound SMS/MMS** - Receive messages via webhook
- **Unified context** - Same conversation across SMS and other channels

## Prerequisites

### Environment Variables

Set these in your OpenClaw config or environment:

```bash
export TWILIO_ACCOUNT_SID="ACxxxxxxxxxxxxxxxxx"
export TWILIO_AUTH_TOKEN="your_auth_token"
export TWILIO_PHONE_NUMBER="+15551234567"
```

### Twilio Account Setup

1. Sign up at https://www.twilio.com
2. Get a phone number (MMS-capable recommended)
3. Copy Account SID and Auth Token from console
4. Configure webhook (see references/webhook_config.md)

## Send Messages

### Send SMS (text only)

```bash
scripts/send_sms.sh "+15551234567" "Hello from OpenClaw!"
```

### Send MMS (with media)

```bash
# Single image
scripts/send_mms.sh "+15551234567" "Check this out!" "https://example.com/image.jpg"

# Multiple media URLs
scripts/send_mms.sh "+15551234567" "Photos" "https://example.com/img1.jpg,https://example.com/img2.jpg"
```

## Receive Messages

Configure Twilio webhook to send incoming messages to OpenClaw.

See **references/webhook_config.md** for complete setup instructions.

## Unified Context Setup

To maintain conversation context across SMS and other channels (Discord, etc.), configure session bindings in OpenClaw config:

```json
{
  "bindings": [
    {
      "agentId": "main",
      "sessionKey": "user-unified",
      "match": { "channel": "discord", "userId": "yourDiscordID" }
    },
    {
      "agentId": "main",
      "sessionKey": "user-unified",
      "match": { "channel": "twilio", "from": "+15551234567" }
    }
  ]
}
```

Both channels share the same `sessionKey`, maintaining unified context.

## Media Support

### Supported formats
- Images: JPEG, PNG, GIF
- Video: MP4, 3GP
- Audio: MP3, WAV
- Documents: PDF, vCard

### Limits
- Up to 10 media attachments per message
- 5MB per file (carrier-dependent)
- MMS availability varies by carrier/country

## Notes

- MMS requires MMS-capable Twilio number
- US/Canada have best MMS support
- Cost: SMS ~$0.0075/msg, MMS ~$0.02-0.05/msg
- Media must be publicly accessible URLs
- Webhook requires publicly accessible endpoint
- **Tested and verified** ✅
