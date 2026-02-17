#!/usr/bin/env node

// Spotify Web API CLI wrapper — zero dependencies (uses built-in fetch)
// Reads SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET, SPOTIFY_REFRESH_TOKEN from env.

import { readFileSync, writeFileSync } from "node:fs";

const TOKEN_CACHE = "/tmp/spotify-token.json";
const BASE = "https://api.spotify.com/v1";

// ── helpers ──────────────────────────────────────────────────────────────────

function die(msg) {
  console.error(JSON.stringify({ error: msg }));
  process.exit(1);
}

function env(key) {
  const v = process.env[key];
  if (!v) die(`Missing env var ${key}`);
  return v;
}

async function getAccessToken() {
  // try cache
  try {
    const cached = JSON.parse(readFileSync(TOKEN_CACHE, "utf8"));
    if (cached.expires_at > Date.now() + 60_000) return cached.access_token;
  } catch {}

  const clientId = env("SPOTIFY_CLIENT_ID");
  const clientSecret = env("SPOTIFY_CLIENT_SECRET");
  const refreshToken = env("SPOTIFY_REFRESH_TOKEN");

  const res = await fetch("https://accounts.spotify.com/api/token", {
    method: "POST",
    headers: {
      "Content-Type": "application/x-www-form-urlencoded",
      Authorization:
        "Basic " + Buffer.from(`${clientId}:${clientSecret}`).toString("base64"),
    },
    body: new URLSearchParams({
      grant_type: "refresh_token",
      refresh_token: refreshToken,
    }),
  });

  if (!res.ok) die(`Token refresh failed: ${res.status} ${await res.text()}`);

  const data = await res.json();
  const cache = {
    access_token: data.access_token,
    expires_at: Date.now() + data.expires_in * 1000,
  };

  try {
    writeFileSync(TOKEN_CACHE, JSON.stringify(cache));
  } catch {}

  return data.access_token;
}

async function api(method, path, body) {
  const token = await getAccessToken();
  const opts = {
    method,
    headers: { Authorization: `Bearer ${token}`, "Content-Type": "application/json" },
  };
  if (body !== undefined) opts.body = JSON.stringify(body);
  const res = await fetch(`${BASE}${path}`, opts);

  // 204 No Content is success for playback commands
  if (res.status === 204) return { ok: true };
  if (!res.ok) {
    const txt = await res.text();
    die(`API ${method} ${path} → ${res.status}: ${txt}`);
  }
  const txt = await res.text();
  if (!txt) return { ok: true };
  try {
    return JSON.parse(txt);
  } catch {
    return { ok: true, body: txt };
  }
}

function deviceParam(args) {
  const idx = args.indexOf("--device");
  if (idx === -1) return { deviceId: null, rest: args };
  const deviceId = args[idx + 1];
  if (!deviceId) die("--device requires a device ID");
  const rest = [...args.slice(0, idx), ...args.slice(idx + 2)];
  return { deviceId, rest };
}

function qs(deviceId) {
  return deviceId ? `?device_id=${encodeURIComponent(deviceId)}` : "";
}

// ── commands ─────────────────────────────────────────────────────────────────

const commands = {
  async status() {
    const data = await api("GET", "/me/player");
    console.log(JSON.stringify(data, null, 2));
  },

  async devices() {
    const data = await api("GET", "/me/player/devices");
    console.log(JSON.stringify(data, null, 2));
  },

  async play(args, deviceId) {
    const uri = args[0];
    const body = {};
    if (uri) {
      if (uri.includes(":track:")) {
        body.uris = [uri];
      } else {
        body.context_uri = uri;
      }
    }
    const result = await api(
      "PUT",
      `/me/player/play${qs(deviceId)}`,
      Object.keys(body).length ? body : undefined,
    );
    console.log(JSON.stringify(result, null, 2));
  },

  async pause(_args, deviceId) {
    const result = await api("PUT", `/me/player/pause${qs(deviceId)}`);
    console.log(JSON.stringify(result, null, 2));
  },

  async next(_args, deviceId) {
    const result = await api("POST", `/me/player/next${qs(deviceId)}`);
    console.log(JSON.stringify(result, null, 2));
  },

  async prev(_args, deviceId) {
    const result = await api("POST", `/me/player/previous${qs(deviceId)}`);
    console.log(JSON.stringify(result, null, 2));
  },

  async queue(args, deviceId) {
    const uri = args[0];
    if (!uri) die("Usage: queue <spotify URI>");
    const result = await api(
      "POST",
      `/me/player/queue?uri=${encodeURIComponent(uri)}${deviceId ? `&device_id=${encodeURIComponent(deviceId)}` : ""}`,
    );
    console.log(JSON.stringify(result, null, 2));
  },

  async search(args) {
    const query = args.join(" ");
    if (!query) die("Usage: search <query>");
    const data = await api(
      "GET",
      `/search?q=${encodeURIComponent(query)}&type=track,album,artist,playlist&limit=5`,
    );
    console.log(JSON.stringify(data, null, 2));
  },

  async vol(args, deviceId) {
    const pct = parseInt(args[0], 10);
    if (isNaN(pct) || pct < 0 || pct > 100) die("Usage: vol <0-100>");
    const result = await api(
      "PUT",
      `/me/player/volume?volume_percent=${pct}${deviceId ? `&device_id=${encodeURIComponent(deviceId)}` : ""}`,
    );
    console.log(JSON.stringify(result, null, 2));
  },

  async shuffle(args, deviceId) {
    const state = args[0];
    if (state !== "true" && state !== "false") die("Usage: shuffle <true|false>");
    const result = await api(
      "PUT",
      `/me/player/shuffle?state=${state}${deviceId ? `&device_id=${encodeURIComponent(deviceId)}` : ""}`,
    );
    console.log(JSON.stringify(result, null, 2));
  },

  async repeat(args, deviceId) {
    const state = args[0];
    if (!["off", "track", "context"].includes(state))
      die("Usage: repeat <off|track|context>");
    const result = await api(
      "PUT",
      `/me/player/repeat?state=${state}${deviceId ? `&device_id=${encodeURIComponent(deviceId)}` : ""}`,
    );
    console.log(JSON.stringify(result, null, 2));
  },
};

// ── main ─────────────────────────────────────────────────────────────────────

const rawArgs = process.argv.slice(2);
const { deviceId, rest } = deviceParam(rawArgs);
const [cmd, ...cmdArgs] = rest;

if (!cmd || !commands[cmd]) {
  die(
    `Usage: spotify-api.mjs <command> [args] [--device <id>]\nCommands: ${Object.keys(commands).join(", ")}`,
  );
}

commands[cmd](cmdArgs, deviceId).catch((e) => die(e.message));
