#!/usr/bin/env python3
"""Generate per-agent command-prefix allowlist files from one core spec."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

VALID_DECISIONS = {"allow", "prompt", "deny"}


@dataclass(frozen=True)
class Rule:
    id: str
    description: str
    pattern: tuple[str, ...]
    decision: str


REPO_ROOT = Path(__file__).resolve().parents[1]
CORE_FILE = REPO_ROOT / "config/command-prefixes/core.json"
OUTPUT_CODEX = REPO_ROOT / ".codex/rules/default.rules"
OUTPUT_GEMINI = REPO_ROOT / ".gemini/policies/command-prefixes.toml"
OUTPUT_CLAUDE = REPO_ROOT / ".claude/settings.json"
OUTPUT_ROO = REPO_ROOT / ".vscode/settings.json"


def load_rules(path: Path) -> list[Rule]:
    data = json.loads(path.read_text(encoding="utf-8"))
    rules_data = data.get("rules")
    if not isinstance(rules_data, list):
        raise ValueError("core config must include a top-level 'rules' list")

    rules: list[Rule] = []
    seen_ids: set[str] = set()
    for index, raw_rule in enumerate(rules_data):
        if not isinstance(raw_rule, dict):
            raise ValueError(f"rule at index {index} must be an object")

        rule_id = raw_rule.get("id")
        description = raw_rule.get("description")
        decision = raw_rule.get("decision")
        pattern = raw_rule.get("pattern")

        if not isinstance(rule_id, str) or not rule_id:
            raise ValueError(f"rule at index {index} has invalid id")
        if rule_id in seen_ids:
            raise ValueError(f"duplicate rule id: {rule_id}")
        seen_ids.add(rule_id)

        if not isinstance(description, str) or not description:
            raise ValueError(f"rule '{rule_id}' has invalid description")

        if not isinstance(decision, str) or decision not in VALID_DECISIONS:
            raise ValueError(
                f"rule '{rule_id}' has invalid decision '{decision}', valid={sorted(VALID_DECISIONS)}"
            )

        if not isinstance(pattern, list) or not pattern:
            raise ValueError(f"rule '{rule_id}' has invalid pattern")

        normalized_pattern: list[str] = []
        for token_index, token in enumerate(pattern):
            if not isinstance(token, str) or not token:
                raise ValueError(
                    f"rule '{rule_id}' has invalid pattern token at index {token_index}"
                )
            normalized_pattern.append(token)

        rules.append(
            Rule(
                id=rule_id,
                description=description,
                pattern=tuple(normalized_pattern),
                decision=decision,
            )
        )

    return rules


def sorted_unique(items: Iterable[str]) -> list[str]:
    return sorted(set(items))


def command_prefix_regex(pattern: tuple[str, ...]) -> str:
    joined = r"\s+".join(re.escape(token) for token in pattern)
    return rf"^{joined}(?:\s|$)"


def render_codex(rules: list[Rule]) -> str:
    lines: list[str] = [
        "# Generated from config/command-prefixes/core.json by scripts/generate-command-prefixes.py",
        "# Do not edit directly.",
        "",
    ]

    for rule in rules:
        pattern_json = json.dumps(list(rule.pattern))
        lines.append(f'prefix_rule(pattern={pattern_json}, decision="{rule.decision}")')

    return "\n".join(lines) + "\n"


def render_gemini(rules: list[Rule]) -> str:
    action_by_decision = {"allow": "allow", "deny": "deny", "prompt": "ask"}

    lines: list[str] = [
        "# Generated from config/command-prefixes/core.json by scripts/generate-command-prefixes.py",
        "# Do not edit directly.",
        "",
    ]

    for priority, rule in enumerate(rules, start=1):
        regex = command_prefix_regex(rule.pattern)
        action_type = action_by_decision[rule.decision]

        lines.extend(
            [
                "[[rules]]",
                f"id = {json.dumps(rule.id)}",
                f"description = {json.dumps(rule.description)}",
                f"priority = {priority}",
                "",
                "[rules.condition]",
                'tool = "run_shell_command"',
                f"args_pattern = {json.dumps(regex)}",
                "",
                "[rules.action]",
                f'type = "{action_type}"',
                "",
            ]
        )

    return "\n".join(lines)


def render_claude(rules: list[Rule]) -> str:
    allow: list[str] = []
    deny: list[str] = []

    for rule in rules:
        command_prefix = " ".join(rule.pattern)
        permission_rule = f"Bash({command_prefix}:*)"
        if rule.decision == "allow":
            allow.append(permission_rule)
        elif rule.decision == "deny":
            deny.append(permission_rule)

    payload = {
        "permissions": {
            "allow": sorted_unique(allow),
            "deny": sorted_unique(deny),
        }
    }
    return json.dumps(payload, indent=2) + "\n"


def render_roo(rules: list[Rule]) -> str:
    allow: list[str] = []
    deny: list[str] = []

    for rule in rules:
        command_prefix = " ".join(rule.pattern)
        if rule.decision == "deny":
            deny.append(command_prefix)
            continue
        allow.append(command_prefix)

    payload = {
        "roo-cline.allowedCommands": sorted_unique(allow),
        "roo-cline.deniedCommands": sorted_unique(deny),
    }
    return json.dumps(payload, indent=2) + "\n"


def write_or_check(path: Path, content: str, check: bool) -> bool:
    if check:
        if not path.exists():
            print(f"out of sync: missing {path.relative_to(REPO_ROOT)}")
            return False
        existing = path.read_text(encoding="utf-8")
        if existing != content:
            print(f"out of sync: {path.relative_to(REPO_ROOT)}")
            return False
        print(f"in sync: {path.relative_to(REPO_ROOT)}")
        return True

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")
    print(f"wrote: {path.relative_to(REPO_ROOT)}")
    return True


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate per-agent command-prefix allowlist files."
    )
    parser.add_argument(
        "--check",
        action="store_true",
        help="Check whether generated files are in sync without writing.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    rules = load_rules(CORE_FILE)

    outputs = {
        OUTPUT_CODEX: render_codex(rules),
        OUTPUT_GEMINI: render_gemini(rules),
        OUTPUT_CLAUDE: render_claude(rules),
        OUTPUT_ROO: render_roo(rules),
    }

    all_ok = True
    for output_path, content in outputs.items():
        if not write_or_check(output_path, content, check=args.check):
            all_ok = False

    return 0 if all_ok else 1


if __name__ == "__main__":
    sys.exit(main())
