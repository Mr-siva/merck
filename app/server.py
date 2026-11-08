"""Tiny HTTP service: GET / -> message, GET /health -> JSON status. Stdlib only."""
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MESSAGE = os.environ.get("APP_MESSAGE", "Hello from the MSD platform service!")


class Handler(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="text/plain; charset=utf-8"):
        data = body.encode()
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/":
            self._send(200, MESSAGE + "\n")
        elif path == "/health":
            self._send(200, json.dumps({"status": "ok"}), "application/json")
        else:
            self._send(404, "not found\n")

    do_HEAD = do_GET

    def log_message(self, fmt, *args):  # one line per request to stderr -> journald
        super().log_message(fmt, *args)


def main():
    port = int(os.environ.get("PORT", "80"))
    host = os.environ.get("BIND", "0.0.0.0")
    ThreadingHTTPServer((host, port), Handler).serve_forever()


if __name__ == "__main__":
    main()
