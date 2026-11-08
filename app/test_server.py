import json
import threading
import unittest
import urllib.error
import urllib.request
from http.server import ThreadingHTTPServer

from server import Handler


class ServerTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.srv = ThreadingHTTPServer(("127.0.0.1", 0), Handler)
        cls.base = f"http://127.0.0.1:{cls.srv.server_address[1]}"
        threading.Thread(target=cls.srv.serve_forever, daemon=True).start()

    @classmethod
    def tearDownClass(cls):
        cls.srv.shutdown()

    def test_root(self):
        with urllib.request.urlopen(self.base + "/") as r:
            self.assertEqual(r.status, 200)
            self.assertIn("Hello", r.read().decode())

    def test_health(self):
        with urllib.request.urlopen(self.base + "/health") as r:
            self.assertEqual(json.load(r), {"status": "ok"})

    def test_404(self):
        with self.assertRaises(urllib.error.HTTPError) as c:
            urllib.request.urlopen(self.base + "/nope")
        self.assertEqual(c.exception.code, 404)


if __name__ == "__main__":
    unittest.main()
