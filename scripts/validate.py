"""Local structural checks and basic credential heuristics; no network access."""
import json
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAX_FILE_BYTES = 256 * 1024
SKIP = {".git", ".local", "exports", "__pycache__", ".venv"}
BASE_FILES = (
    "context/rules.md", "context/privacy.md", "context/memory-policy.md",
    "context/preferences.json",
)
REQUIRED = (
    "README.md", "AGENTS.md", "CLAUDE.md", ".gitignore", *BASE_FILES,
    "projects/README.md", "handoffs/README.md", "skills/README.md",
    "templates/README.md", "scripts/README.md",
)
SLUG = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*")
# shortcut: heuristic detection misses many secrets and PII; review diffs manually.
PATTERNS = {
    "private-key": re.compile(r"-----BEGIN (?:RSA |EC |OPENSSH |DSA )?PRIVATE KEY-----"),
    "provider-token": re.compile(r"\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,}|AKIA[A-Z0-9]{16})\b"),
    "credential-assignment": re.compile(
        r'''(?i)["']?\b(?:api[_-]?key|password|passwd|access[_-]?token|client[_-]?secret)["']?\s*[:=]\s*["']([^"'\n]{8,})["']'''
    ),
    "credential-url": re.compile(r"https?://[^\s/:@]+:[^\s/@]+@"),
}


def read_safe(root, relative):
    path = Path(relative)
    if path.is_absolute() or ".." in path.parts:
        raise ValueError(f"{relative}: path outside repository")
    current = root
    for part in path.parts:
        current = current / part
        if current.is_symlink():
            raise ValueError(f"{relative}: symlink is not an input file")
    if not current.is_file():
        raise ValueError(f"{relative}: missing file")
    data = current.read_bytes()
    if len(data) > MAX_FILE_BYTES:
        raise ValueError(f"{relative}: exceeds 256 KiB")
    return data.decode("utf-8")


def credential_issues(relative, content):
    path = Path(relative)
    issues = []
    if (path.name == ".env" or path.name.startswith(".env.")
            or path.suffix.lower() in {".pem", ".key", ".p12", ".pfx"}
            or path.name in {"credentials.json", "id_rsa", "id_ed25519"}
            or {"secrets", "private", "raw-conversations"}.intersection(path.parts)):
        issues.append(f"{relative}: prohibited sensitive filename")
    for label, pattern in PATTERNS.items():
        for match in pattern.finditer(content):
            line = content.count("\n", 0, match.start()) + 1
            issues.append(f"{relative}:{line}: possible {label}; review locally")
    return issues


def git_info(root):
    try:
        top = subprocess.run(
            ["git", "-C", str(root), "rev-parse", "--show-toplevel"],
            capture_output=True, text=True, check=True,
        ).stdout.strip()
        return Path(top).resolve() == root.resolve()
    except (OSError, subprocess.CalledProcessError):
        return False


def candidate_files(root):
    if git_info(root):
        result = subprocess.run(
            ["git", "-C", str(root), "ls-files", "-z", "--cached", "--others", "--exclude-standard"],
            capture_output=True, check=True,
        )
        return sorted(set(result.stdout.decode("utf-8").rstrip("\0").split("\0")) - {""})
    return sorted(
        p.relative_to(root).as_posix() for p in root.rglob("*")
        if not SKIP.intersection(p.relative_to(root).parts)
        and (p.is_file() or p.is_symlink())
    )


def preference_issues(content):
    data = json.loads(content)
    if not isinstance(data, dict) or set(data) != {"schema_version", "preferences"}:
        return ["preferences: expected schema_version and preferences"]
    if type(data["schema_version"]) is not int or data["schema_version"] != 1:
        return ["preferences: unsupported schema version"]
    if not isinstance(data["preferences"], list):
        return ["preferences: expected list"]
    seen = set()
    for item in data["preferences"]:
        fields = {"id", "statement", "scope", "confirmed_on", "source"}
        if (not isinstance(item, dict) or set(item) != fields
                or not all(isinstance(v, str) and v.strip() for v in item.values())):
            return ["preferences: each entry needs nonempty id, statement, scope, confirmed_on, source"]
        if not SLUG.fullmatch(item["id"]) or item["id"] in seen:
            return ["preferences: invalid or duplicate id"]
        seen.add(item["id"])
        try:
            parsed = date.fromisoformat(item["confirmed_on"])
            if parsed.isoformat() != item["confirmed_on"]:
                raise ValueError("noncanonical date")
        except ValueError:
            return ["preferences: confirmed_on must be YYYY-MM-DD"]
    return []


def skill_issues(relative, content):
    name = Path(relative).parent.name
    front = re.match(r"\A---\n(.*?)\n---(?:\n|$)", content, re.S)
    if not front:
        return [f"{relative}: missing YAML frontmatter"]
    fields = {}
    for line in front[1].splitlines():
        if ":" in line:
            key, value = line.split(":", 1)
            fields[key] = value.strip().strip("\"'")
    if not SLUG.fullmatch(name) or len(name) > 64 or fields.get("name") != name:
        return [f"{relative}: invalid name or folder mismatch"]
    if not fields.get("description") or fields["description"] in {"|", ">", "|-", ">-"}:
        return [f"{relative}: use a nonempty single-line description"]
    return []


def validate(root):
    issues = []
    for relative in REQUIRED:
        if not (root / relative).is_file():
            issues.append(f"{relative}: required file missing")
    for relative in candidate_files(root):
        path = root / relative
        if path.is_symlink() and relative in {".agents/skills", ".claude/skills"}:
            if path.resolve() != (root / "skills").resolve():
                issues.append(f"{relative}: adapter must link to this repository's skills/")
            continue
        try:
            content = read_safe(root, relative)
            issues.extend(credential_issues(relative, content))
            if path.suffix == ".json":
                json.loads(content)
            if relative == "context/preferences.json":
                issues.extend(preference_issues(content))
            if relative.startswith("skills/") and path.name == "SKILL.md":
                issues.extend(skill_issues(relative, content))
            if path.suffix == ".md":
                for target in re.findall(r"\[[^\]]*\]\(([^\s)]+)\)", content):
                    if re.match(r"[a-z][a-z0-9+.-]*:", target, re.I) or target.startswith("#"):
                        continue
                    dest = (path.parent / target.split("#", 1)[0]).resolve()
                    if not dest.is_relative_to(root.resolve()) or not dest.exists():
                        issues.append(f"{relative}: missing or external local link: {target}")
        except (ValueError, OSError) as exc:
            # Do not echo malformed JSON or file contents in diagnostics.
            issues.append(f"{relative}: cannot validate ({type(exc).__name__})")
    return issues


if __name__ == "__main__":
    try:
        problems = validate(ROOT)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"Validation failed: {type(exc).__name__}", file=sys.stderr)
        sys.exit(1)
    if problems:
        print("\n".join(problems), file=sys.stderr)
        sys.exit(1)
    print("PASS: structure, references, preferences, skill metadata, basic credential checks.")
    print("Manual privacy and staged-diff review are still required.")
