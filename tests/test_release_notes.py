"""Check that publication uses only the changelog section matching the tag."""

import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("release_notes", ROOT / ".github/scripts/release_notes.py")
release_notes = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release_notes)


class ReleaseNotesTests(unittest.TestCase):
    def test_exact_version_and_subheadings(self):
        text = "# Changelog\n\n## 1.9.4\n\nStable.\n\n## 1.9.4-alpha.1\n\n### Changes\n\nAlpha.\n\n## 1.9.3\nOld.\n"
        notes = release_notes.extract_release_notes("refs/tags/v1.9.4-alpha.1", text)
        self.assertEqual(notes, "## 1.9.4-alpha.1\n\n### Changes\n\nAlpha.\n")

    def test_real_changelog_releases(self):
        text = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
        for version in ("1.9.4", "1.7.1"):
            with self.subTest(version=version):
                notes = release_notes.extract_release_notes("refs/tags/v" + version, text)
                self.assertTrue(notes.startswith("## " + version + "\n"))
                self.assertEqual(sum(line.startswith("## ") for line in notes.splitlines()), 1)

    def test_beta_and_crlf(self):
        text = "## 1.9.5-beta.1\r\n\r\nBeta.\r\n\r\n## 1.9.4\r\nOld.\r\n"
        notes = release_notes.extract_release_notes("refs/tags/v1.9.5-beta.1", text)
        self.assertIn("Beta.", notes)
        self.assertNotIn("1.9.4", notes)

    def test_missing_duplicate_and_invalid_ref_fail(self):
        for ref, text in (
            ("refs/tags/v1.9.5", "## 1.9.4\ntext\n"),
            ("refs/tags/v1.9.4", "## 1.9.4\none\n## 1.9.4\ntwo\n"),
            ("refs/heads/main", "## 1.9.4\ntext\n"),
            ("refs/tags/v1.9.4", "## 1.9.4\n\n"),
        ):
            with self.subTest(ref=ref, text=text), self.assertRaises(ValueError):
                release_notes.extract_release_notes(ref, text)


if __name__ == "__main__":
    unittest.main()
