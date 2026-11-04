"""Regression for relocated archives whose original path still exists."""
import hashlib
import importlib.util
import tempfile
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location("checksum", Path(__file__).with_name("verify-checksum.py"))
checksum = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checksum)


class ChecksumTest(unittest.TestCase):
    def test_relocated_legacy_and_portable_sidecars(self):
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            original = root / "original.dump"
            original.write_bytes(b"original backup")
            copied = root / "renamed.dump"
            sidecar = Path(str(copied) + ".sha256")
            digest = hashlib.sha256(original.read_bytes()).hexdigest()
            for filename in (str(original), "original.dump"):
                with self.subTest(filename=filename):
                    copied.write_bytes(original.read_bytes())
                    sidecar.write_text(f"{digest}  {filename}\n")
                    checksum.verify(copied)
                    copied.write_bytes(b"tampered backup")
                    with self.assertRaisesRegex(ValueError, "mismatch"):
                        checksum.verify(copied)
            sidecar.write_text("not a checksum\n")
            with self.assertRaisesRegex(ValueError, "Malformed"):
                checksum.verify(copied)


if __name__ == "__main__":
    unittest.main()
