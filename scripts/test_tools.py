"""Behavioral checks for selection, boundaries, and basic credential handling."""
import json
import hashlib
import subprocess
import tempfile
import unittest
from pathlib import Path

from export_context import build_bundle, selected_paths
from validate import BASE_FILES, MAX_FILE_BYTES, candidate_files, credential_issues, preference_issues, read_safe, validate_library


class ToolTests(unittest.TestCase):
    def test_windows_batch_encoding(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            content = "@echo off\r\necho 安装完成\r\n"
            (root / "install.bat").write_bytes(content.encode("gbk"))
            self.assertEqual(read_safe(root, "install.bat"), content)
            (root / "guide.md").write_bytes(content.encode("gbk"))
            with self.assertRaises(UnicodeDecodeError):
                read_safe(root, "guide.md")

    def test_import_manifest_detects_tampering_and_unlisted_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            library = root / "library"
            library.mkdir()
            (library / "README.md").write_text("demo", encoding="utf-8")
            (library / "demo.md").write_bytes(b"demo")
            manifest = dict(schema_version=1, files=[dict(path="demo.md", bytes=4,
                sha256=hashlib.sha256(b"demo").hexdigest())])
            (library / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
            self.assertEqual(validate_library(root), [])
            (library / "demo.md").write_bytes(b"changed")
            self.assertTrue(any("mismatch" in p for p in validate_library(root)))
            (library / "extra.md").write_bytes(b"extra")
            self.assertTrue(any("unlisted" in p for p in validate_library(root)))

    def test_import_manifest_rejects_escape_and_symlink(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            library = root / "library"
            library.mkdir()
            (library / "README.md").write_text("demo", encoding="utf-8")
            manifest = dict(schema_version=1, files=[dict(path="../outside.md", bytes=0, sha256="")])
            (library / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
            self.assertTrue(any("unsafe" in p for p in validate_library(root)))
            (library / "link.md").symlink_to(library / "README.md")
            manifest["files"][0]["path"] = "link.md"
            (library / "manifest.json").write_text(json.dumps(manifest), encoding="utf-8")
            with self.assertRaises(ValueError):
                validate_library(root)

    def test_selection_is_explicit(self):
        self.assertEqual(selected_paths(), list(BASE_FILES))
        chosen = selected_paths("example", "handoffs/example/demo.md", ["resume-work", "resume-work"])
        self.assertEqual(chosen.count("skills/resume-work/SKILL.md"), 1)
        self.assertIn("projects/example/STATUS.md", chosen)
        for args in [("../other", None, []), (None, "handoffs/example/demo.md", []),
                     ("example", "handoffs/other/demo.md", []),
                     ("example", "handoffs/example/../private.md", []),
                     (None, None, ["../../private"])]:
            with self.assertRaises(ValueError):
                selected_paths(*args)

    def test_missing_symlink_escape_and_size_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "large.md").write_bytes(b"a" * (MAX_FILE_BYTES + 1))
            (root / "link.md").symlink_to(root / "large.md")
            for name in ("missing.md", "../outside.md", "/absolute.md", "link.md", "large.md"):
                with self.assertRaises(ValueError):
                    read_safe(root, name)

    def test_bundle_includes_hashes_but_no_implicit_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            content = "# chosen\n```text\nexample\n```\n"
            (root / "chosen.md").write_text(content, encoding="utf-8")
            (root / "unselected.md").write_text("NEVER_INCLUDE_THIS", encoding="utf-8")
            bundle = build_bundle(root, ["chosen.md"])
            self.assertIn("SHA-256", bundle)
            self.assertIn(content.rstrip(), bundle)
            self.assertIn("````markdown", bundle)
            self.assertNotIn("NEVER_INCLUDE_THIS", bundle)

    def test_secret_rejected_without_echoing_value(self):
        token = "ghp_" + "A" * 30
        problems = credential_issues("notes.md", token)
        self.assertTrue(problems)
        self.assertNotIn(token, "\n".join(problems))
        self.assertTrue(credential_issues(".env", ""))
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "bad.md").write_text(token, encoding="utf-8")
            with self.assertRaises(ValueError) as failure:
                build_bundle(root, ["bad.md"])
            self.assertNotIn(token, str(failure.exception))

    def test_preference_schema_rejects_duplicates_and_bad_dates(self):
        item = dict(id="language", statement="confirmed example", scope="demo",
                    confirmed_on="2026-10-20", source="explicit demo confirmation")
        def check(items):
            return preference_issues(json.dumps(dict(schema_version=1, preferences=items)))
        self.assertFalse(check([]))
        self.assertFalse(check([item]))
        self.assertTrue(check([item, item]))
        self.assertTrue(check([dict(item, confirmed_on="yesterday")]))

    def test_tracked_ignored_file_is_still_checked(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            subprocess.run(["git", "init", "-q", str(root)], check=True)
            (root / ".gitignore").write_text(".env\n.local/\n", encoding="utf-8")
            (root / ".env").write_text("", encoding="utf-8")
            subprocess.run(["git", "-C", str(root), "add", "-f", ".env"], check=True)
            (root / ".local").mkdir()
            (root / ".local" / "draft.md").write_text("local", encoding="utf-8")
            files = candidate_files(root)
            self.assertIn(".env", files)
            self.assertNotIn(".local/draft.md", files)


if __name__ == "__main__":
    unittest.main()
