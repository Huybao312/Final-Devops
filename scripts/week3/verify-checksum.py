"""Validate the selected archive, never a path supplied by its sidecar."""
import hashlib
import re
import sys
from pathlib import Path


def verify(archive: Path) -> None:
    lines = Path(str(archive) + ".sha256").read_text().splitlines()
    if len(lines) != 1 or not re.fullmatch(r"[a-fA-F0-9]{64}\s+.+", lines[0]):
        raise ValueError("Malformed SHA-256 sidecar")
    expected = lines[0][:64].lower()
    digest = hashlib.sha256()
    with archive.open("rb") as stream:
        for chunk in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(chunk)
    if digest.hexdigest() != expected:
        raise ValueError("Archive checksum mismatch; restore refused")


if __name__ == "__main__":
    try:
        verify(Path(sys.argv[1]))
    except (OSError, ValueError, IndexError) as error:
        print(f"FAIL: {error}", file=sys.stderr)
        sys.exit(1)
    print("PASS: selected archive SHA-256 verified")
