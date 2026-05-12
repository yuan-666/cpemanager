import unittest

from cpemanager.xmlutil import parse_flat, parse_root, tag_text, xml_text


class XMLUtilTests(unittest.TestCase):
    def test_parse_flat_response(self):
        data = parse_flat("<response><SignalIconNr>5</SignalIconNr><maxsignal>5</maxsignal></response>")

        self.assertEqual(data["SignalIconNr"], "5")
        self.assertEqual(data["maxsignal"], "5")

    def test_tag_text_finds_nested_value(self):
        root = parse_root("<response><nr_info><lock_mode>3</lock_mode></nr_info></response>")

        self.assertEqual(tag_text(root, "lock_mode"), "3")

    def test_xml_text_escapes_payload_values(self):
        self.assertEqual(xml_text("a&b<c"), "a&amp;b&lt;c")


if __name__ == "__main__":
    unittest.main()
