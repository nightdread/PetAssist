"""Extract the exact tagged release notes for the packager."""

import re
import sys
from pathlib import Path


def extract_release_notes(ref: str, changelog: str) -> str:
    """Return exactly one version section, including its level-2 heading."""
    match = re.fullmatch(r"refs/tags/v(\d+\.\d+\.\d+(?:-(?:alpha|beta)\.\d+)?)", ref)
    if not match:
        raise ValueError("Release must run from a version tag, e.g. v1.9.4-alpha.1")
    version = match.group(1)
    headings = list(re.finditer(r"(?m)^##[ \t]+([^\r\n]+?)[ \t]*\r?$", changelog))
    matching = [index for index, heading in enumerate(headings) if heading.group(1) == version]
    if len(matching) != 1:
        raise ValueError(f"Expected exactly one CHANGELOG.md section for {version}; found {len(matching)}")
    index = matching[0]
    end = headings[index + 1].start() if index + 1 < len(headings) else len(changelog)
    section = changelog[headings[index].start():end].strip()
    if not section.partition("\n")[2].strip():
        raise ValueError(f"CHANGELOG.md section for {version} is empty")
    return section + "\n"


def main() -> None:
    if len(sys.argv) != 4:
        raise SystemExit("Usage: release_notes.py <refs/tags/vVERSION> <changelog> <output>")
    try:
        text = Path(sys.argv[2]).read_text(encoding="utf-8")
        notes = extract_release_notes(sys.argv[1], text)
        Path(sys.argv[3]).write_text(notes, encoding="utf-8", newline="\n")
    except (OSError, ValueError) as error:
        raise SystemExit(str(error)) from error


if __name__ == "__main__":
    main()
