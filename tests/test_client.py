import unittest

from cpemanager.client import HuaweiCPE


class ClientParsingTests(unittest.TestCase):
    def test_parse_neighbor_cell_list(self):
        cells = HuaweiCPE.parse_cell_list(
            "633984,78,360,-86dBm,-11dB,-58dBm,23dB;"
            "504990,41,12,-99dBm,-15dB,-70dBm,8dB;"
        )

        self.assertEqual(cells[0]["earfcn"], "633984")
        self.assertEqual(cells[0]["band"], "78")
        self.assertEqual(cells[0]["pci"], "360")
        self.assertEqual(cells[1]["sinr"], "8dB")

    def test_parse_secondary_cell_list(self):
        cells = HuaweiCPE.parse_cell_list(
            "633984,78,100M,360,-86dBm,-11dB,-58dBm,23dB;",
            is_sec_cell=True,
        )

        self.assertEqual(cells[0]["bw"], "100M")
        self.assertEqual(cells[0]["pci"], "360")

    def test_hex_to_bands(self):
        self.assertEqual(HuaweiCPE.hex_to_bands("5"), [1, 3])

    def test_build_lock_info_escapes_values(self):
        cpe = HuaweiCPE()
        body = cpe._build_lock_info("3", "41,78")

        self.assertIn("<lock_mode>3</lock_mode>", body)
        self.assertIn("<band>41</band>", body)
        self.assertIn("<band>78</band>", body)
        self.assertIn("<all_bands>41,78</all_bands>", body)


if __name__ == "__main__":
    unittest.main()
