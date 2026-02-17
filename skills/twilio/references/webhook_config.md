# Twilio Webhook Configuration

Configure Twilio to send incoming SMS/MMS to OpenClaw for unified cross-channel context.

## Overview

When someone texts your Twilio number:
1. Twilio receives the message
2. Twilio HTTP POSTs to your OpenClaw webhook
3. OpenClaw processes in same session as Discord/other channels
4. Maintains unified conversation context

## Step 1: Configure OpenClaw Webhook

Add to `openclaw.json`:

```json
{
  "hooks": {
    "enabled": true,
    "path": "/hooks",
    "mappings": [
      {
        "match": { "path": "twilio" },
        "action": "agent",
        "wakeMode": "now",
        "sessionKey": "user-unified",
        "messageTemplate": "SMS from {{From}}: {{Body}}",
        "deliver": true,
        "channel": "discord"
      }
    ]
  }
}
```

## Step 2: Get Webhook URL

Format: `https://your-domain.com/hooks/twilio`

For Fly.io: `https://your-app.fly.dev/hooks/twilio`

## Step 3: Configure Twilio

1. Go to https://console.twilio.com
2. Navigate to: Phone Numbers → Manage → Active numbers
3. Click your phone number
4. Under "Messaging Configuration" → "A MESSAGE COMES IN":
   - Webhook: `https://your-domain.com/hooks/twilio`
   - HTTP POST
5. Save

## Step 4: Unified Context

Configure session bindings so SMS + Discord = same conversation:

```json
{
  "bindings": [
    {
      "agentId": "main",
      "sessionKey": "scott-unified",
      "match": { "channel": "discord", "userId": "yourDiscordID" }
    },
    {
      "agentId": "main",
      "sessionKey": "scott-unified",
      "match": { "channel": "twilio", "from": "+19142187869" }
    }
  ]
}
```

Now texting maintains full context from Discord!

## Webhook Payload

Twilio sends:

| Field | Description |
|-------|-------------|
| `From` | Sender's phone number |
| `To` | Your Twilio number |
| `Body` | Message text |
| `NumMedia` | Number of attachments |
| `MediaUrl0`, `MediaUrl1`, ... | Media URLs |

## Receiving Media (MMS)

When someone sends an image:

```json
{
  "From": "+19142187869",
  "Body": "Check this out!",
  "NumMedia": "1",
  "MediaUrl0": "https://api.twilio.com/.../Media/ME123",
  "MediaContentType0": "image/jpeg"
}
```

OpenClaw can download and process the media.

## Security (Optional)

Validate Twilio signatures to ensure requests are authentic:

```json
{
  "hooks": {
    "twilio": {
      "validateSignature": true,
      "authToken": "your_auth_token"
    }
  }
}
```
