---
name: dj
description: Control Spotify playback (play, pause, search, queue) on any device via Web API.
homepage: https://developer.spotify.com/documentation/web-api
metadata:
  {
    "openclaw":
      {
        "emoji": "🎧",
        "requires":
          {
            "bins": ["node"],
            "env":
              [
                "SPOTIFY_CLIENT_ID",
                "SPOTIFY_CLIENT_SECRET",
                "SPOTIFY_REFRESH_TOKEN",
              ],
          },
      },
  }
---

# DJ — Spotify Web API

Control Spotify playback on any device (Mac, phone, speakers) from a headless server. Uses the Spotify Web API with OAuth refresh tokens — no browser needed at runtime.

**Requires:** Spotify Premium account.

## CLI

All commands use `node skills/dj/spotify-api.mjs <command>`. Output is JSON.

### Playback status

```bash
node skills/dj/spotify-api.mjs status
```

Returns current track, device, progress, shuffle/repeat state. Returns `null` if nothing is playing.

### List devices

```bash
node skills/dj/spotify-api.mjs devices
```

Returns available Spotify Connect devices (name, id, type, is_active, volume).

### Play / resume

```bash
# Resume current playback
node skills/dj/spotify-api.mjs play

# Play a specific track
node skills/dj/spotify-api.mjs play spotify:track:6rqhFgbbKwnb9MLmUQDhG6

# Play an album or playlist
node skills/dj/spotify-api.mjs play spotify:album:1DFixLWuPkv3KT3TnV35m3
node skills/dj/spotify-api.mjs play spotify:playlist:37i9dQZF1DXcBWIGoYBM5M

# Play on a specific device
node skills/dj/spotify-api.mjs play spotify:track:... --device DEVICE_ID
```

### Pause

```bash
node skills/dj/spotify-api.mjs pause
```

### Next / Previous

```bash
node skills/dj/spotify-api.mjs next
node skills/dj/spotify-api.mjs prev
```

### Add to queue

```bash
node skills/dj/spotify-api.mjs queue spotify:track:6rqhFgbbKwnb9MLmUQDhG6
```

### Search

```bash
node skills/dj/spotify-api.mjs search Miles Davis Kind of Blue
```

Returns up to 5 results each for tracks, albums, artists, and playlists. Use the `uri` field from results to play or queue.

### Volume

```bash
node skills/dj/spotify-api.mjs vol 50
```

### Shuffle / Repeat

```bash
node skills/dj/spotify-api.mjs shuffle true
node skills/dj/spotify-api.mjs shuffle false
node skills/dj/spotify-api.mjs repeat off      # off | track | context
```

## Typical workflows

**"Play some Miles Davis"**

1. `search Miles Davis` — pick a top track or album URI from results
2. `play <uri>` — start playback

**"Queue up a few songs"**

1. `search <song>` — find the track URI
2. `queue <uri>` — repeat for each song

**"What's playing?"**

1. `status` — shows current track, artist, album, progress, device

**"Play on my kitchen speaker"**

1. `devices` — find the device ID for the kitchen speaker
2. `play --device <id>` — or `play <uri> --device <id>`

## Setup (one-time)

1. Create a Spotify Developer App at https://developer.spotify.com/dashboard
   - Redirect URI: `http://localhost:8888/callback`
   - Note the **Client ID** and **Client Secret**

2. Authorize and get a refresh token (one-time browser step):
   - Open: `https://accounts.spotify.com/authorize?client_id=YOUR_CLIENT_ID&response_type=code&redirect_uri=http://localhost:8888/callback&scope=user-modify-playback-state%20user-read-playback-state%20user-read-currently-playing`
   - After authorizing, grab the `code` from the redirect URL
   - Exchange it: `curl -X POST https://accounts.spotify.com/api/token -d grant_type=authorization_code -d code=CODE -d redirect_uri=http://localhost:8888/callback -H "Authorization: Basic $(echo -n CLIENT_ID:CLIENT_SECRET | base64)"`
   - Save the `refresh_token` from the response

3. Set environment variables (or Fly secrets):
   ```bash
   fly secrets set SPOTIFY_CLIENT_ID=xxx SPOTIFY_CLIENT_SECRET=xxx SPOTIFY_REFRESH_TOKEN=xxx
   ```

## Notes

- The access token is auto-refreshed and cached in `/tmp/spotify-token.json`.
- Playback commands (play, pause, next, prev, vol) require an active Spotify session on at least one device. If no device is active, open Spotify on any device first, then use `--device <id>`.
- All output is JSON. Parse it to extract track names, URIs, device IDs, etc.
