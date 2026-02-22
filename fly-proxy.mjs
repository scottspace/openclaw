/**
 * Minimal reverse proxy for Fly.io deployment.
 *
 * Routes:
 *   /gmail-pubsub* → gog gmail watch serve (127.0.0.1:8788)
 *   everything else → openclaw gateway     (127.0.0.1:3001)
 *
 * Needed because Google Pub/Sub push requires a public HTTPS endpoint,
 * and gog serve runs on a separate local port from the gateway.
 */

import { createServer, request } from "node:http";
import { connect } from "node:net";

const LISTEN_PORT = parseInt(process.env.PROXY_PORT || "3000", 10);
const GATEWAY_PORT = parseInt(process.env.GATEWAY_PORT || "3001", 10);
const GOG_PORT = parseInt(process.env.GOG_SERVE_PORT || "8788", 10);

const server = createServer((req, res) => {
  const url = req.url || "/";
  const isGogRoute = url.startsWith("/gmail-pubsub");
  const targetPort = isGogRoute ? GOG_PORT : GATEWAY_PORT;

  const proxyReq = request(
    {
      hostname: "127.0.0.1",
      port: targetPort,
      path: url,
      method: req.method,
      headers: req.headers,
    },
    (proxyRes) => {
      res.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
      proxyRes.pipe(res);
    },
  );

  proxyReq.on("error", () => {
    if (!res.headersSent) {
      res.writeHead(502, { "Content-Type": "text/plain" });
      res.end("Bad Gateway");
    }
  });

  req.pipe(proxyReq);
});

// WebSocket upgrade: pipe raw TCP to the gateway
server.on("upgrade", (req, socket, head) => {
  const targetPort = GATEWAY_PORT;
  const backend = connect(targetPort, "127.0.0.1", () => {
    // Reconstruct the original HTTP upgrade request and send it to the backend
    const headers = [`${req.method} ${req.url} HTTP/1.1`];
    for (let i = 0; i < req.rawHeaders.length; i += 2) {
      headers.push(`${req.rawHeaders[i]}: ${req.rawHeaders[i + 1]}`);
    }
    backend.write(headers.join("\r\n") + "\r\n\r\n");
    if (head.length > 0) {
      backend.write(head);
    }
    // Bidirectional pipe
    socket.pipe(backend);
    backend.pipe(socket);
  });

  backend.on("error", () => socket.destroy());
  socket.on("error", () => backend.destroy());
});

server.listen(LISTEN_PORT, "0.0.0.0", () => {
  console.log(
    `[fly-proxy] listening on 0.0.0.0:${LISTEN_PORT} → gateway:${GATEWAY_PORT} | gog:${GOG_PORT}`,
  );
});
