import unittest

from cpemanager.cli import build_parser, normalize_raw_endpoint


class CLITests(unittest.TestCase):
    def test_antenna_accepts_legacy_option_name(self):
        args = build_parser().parse_args(["antenna", "--antenna", "1"])

        self.assertEqual(args.antenna, "1")

    def test_raw_accepts_known_endpoint_path(self):
        self.assertEqual(normalize_raw_endpoint("/api/device/signal"), "/api/device/signal")

    def test_raw_accepts_full_url(self):
        url = "http://192.168.8.1/api/device/signal"

        self.assertEqual(normalize_raw_endpoint(url), url)


if __name__ == "__main__":
    unittest.main()
