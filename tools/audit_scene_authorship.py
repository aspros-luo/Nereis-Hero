#!/usr/bin/env python3
"""Audit authored Godot scene structure and runtime node construction.

This tool is intentionally read-only. It reports candidates for review; it never
deletes code or rewrites scenes. Dynamic gameplay objects are not automatically
bugs, so findings must be reviewed in context before any refactor.
"""
from __future__ import annotations

import argparse
import json
import re
from collections import Counter, defaultdict
from pathlib import Path

NODE_DECLARATION = re.compile(r'^\[node\s+name="([^"]+)"\s+type="([^"]+)"(?:\s+parent="([^"]+)")?', re.M)
SCRIPT_RESOURCE = re.compile(r'^\[ext_resource.*?path="res://([^"]+\.gd)"', re.M)
NODE_NEW = re.compile(
    r'\b(Node2D|Node|Area2D|StaticBody2D|CharacterBody2D|RigidBody2D|'
    r'CollisionShape2D|Marker2D|Control|CanvasLayer|Camera2D|Label|RichTextLabel|'
    r'ColorRect|Sprite2D|TileMapLayer|Polygon2D|PanelContainer|VBoxContainer|'
    r'HBoxContainer|Button|ProgressBar|AnimationPlayer|RayCast2D|Line2D)\.new\s*\('
)
ADD_CHILD = re.compile(r'(?<![\w.])add_child\s*\(')
RESOURCE_PATH = re.compile(r'res://([^"\s]+)')
FUNCTION = re.compile(r'^\s*(?:static\s+)?func\s+([A-Za-z_]\w*)\s*\(', re.M)
SCRIPT_SUFFIXES = {".gd", ".tscn", ".tres", ".godot", ".cfg", ".json", ".gdshader"}


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        return ""


def scene_inventory(root: Path) -> list[dict]:
    inventory = []
    for path in sorted((root / "scenes").rglob("*.tscn")):
        source = read_text(path)
        nodes = NODE_DECLARATION.findall(source)
        scripts = SCRIPT_RESOURCE.findall(source)
        inventory.append({
            "path": path.relative_to(root).as_posix(),
            "node_count": len(nodes),
            "root_name": nodes[0][0] if nodes else None,
            "root_type": nodes[0][1] if nodes else None,
            "scripts": scripts,
            "root_only": len(nodes) <= 1,
        })
    return inventory


def script_findings(root: Path) -> tuple[list[dict], list[dict], list[dict]]:
    builders = []
    large_scripts = []
    duplicate_functions = []
    for path in sorted(root.rglob("*.gd")):
        if ".git" in path.parts or ".godot" in path.parts:
            continue
        source = read_text(path)
        rel = path.relative_to(root).as_posix()
        lines = source.splitlines()
        funcs = FUNCTION.findall(source)
        counts = Counter(funcs)
        duplicates = sorted(name for name, count in counts.items() if count > 1)
        if duplicates:
            duplicate_functions.append({"path": rel, "functions": duplicates})
        if len(lines) >= 1000:
            large_scripts.append({"path": rel, "lines": len(lines), "bytes": len(source.encode("utf-8"))})
        node_lines = []
        for index, line in enumerate(lines, 1):
            if NODE_NEW.search(line):
                node_lines.append({"line": index, "kind": "new", "code": line.strip()[:180]})
            if ADD_CHILD.search(line):
                node_lines.append({"line": index, "kind": "add_child", "code": line.strip()[:180]})
        if node_lines:
            # Classification is a triage hint only, not a verdict.
            if rel.startswith(("scripts/levels/", "scripts/world/")) or rel in {
                "scripts/core/boot.gd", "scripts/core/scene_transition.gd"
            }:
                category = "high_priority_scene_structure_review"
            elif rel.startswith(("scripts/effects/", "scripts/combat/")):
                category = "likely_transient_or_combat_runtime"
            else:
                category = "review_context"
            builders.append({
                "path": rel,
                "category": category,
                "node_operation_count": len(node_lines),
                "operations": node_lines,
            })
    return builders, large_scripts, duplicate_functions


def resource_reference_findings(root: Path) -> list[dict]:
    missing = []
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix not in SCRIPT_SUFFIXES:
            continue
        if ".git" in path.parts or ".godot" in path.parts:
            continue
        source = read_text(path)
        for match in RESOURCE_PATH.finditer(source):
            target = root / match.group(1)
            if not target.exists():
                line = source.count("\n", 0, match.start()) + 1
                missing.append({
                    "source": path.relative_to(root).as_posix(),
                    "line": line,
                    "reference": "res://" + match.group(1),
                })
    return missing


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--json", dest="json_path", type=Path, help="Optional JSON report path.")
    parser.add_argument("--strict", action="store_true", help="Exit non-zero when scene-structure risks are found.")
    args = parser.parse_args()
    root = args.root.resolve()

    scenes = scene_inventory(root)
    builders, large_scripts, duplicate_functions = script_findings(root)
    missing_resources = resource_reference_findings(root)
    report = {
        "schema_version": 1,
        "project_root": str(root),
        "summary": {
            "scenes": len(scenes),
            "root_only_scenes": sum(item["root_only"] for item in scenes),
            "scripts_with_runtime_node_construction": len(builders),
            "large_scripts_1000_lines_or_more": len(large_scripts),
            "duplicate_function_definitions": len(duplicate_functions),
            "missing_res_resource_references": len(missing_resources),
        },
        "root_only_scenes": [item for item in scenes if item["root_only"]],
        "runtime_node_construction": builders,
        "large_scripts": large_scripts,
        "duplicate_function_definitions": duplicate_functions,
        "missing_res_resource_references": missing_resources,
        "note": "Static triage only. Review false positives and verify scene loading in the Godot editor/runtime.",
    }
    rendered = json.dumps(report, ensure_ascii=False, indent=2)
    if args.json_path:
        args.json_path.parent.mkdir(parents=True, exist_ok=True)
        args.json_path.write_text(rendered + "\n", encoding="utf-8")

    print("NEREIS-HERO SCENE AUTHORSHIP AUDIT")
    for key, value in report["summary"].items():
        print(f"- {key}: {value}")
    print("\nRoot-only scenes (highest priority for editor-visible structure):")
    for item in report["root_only_scenes"]:
        print(f"  - {item['path']} [{item['root_name']}:{item['root_type']}] scripts={item['scripts']}")
    print("\nScripts with runtime node construction (triage only):")
    for item in builders:
        print(f"  - {item['path']}: {item['node_operation_count']} operations [{item['category']}]")
    print("\nLarge scripts:")
    for item in large_scripts:
        print(f"  - {item['path']}: {item['lines']} lines / {item['bytes']} bytes")
    if missing_resources:
        print("\nMissing res:// references:")
        for item in missing_resources:
            print(f"  - {item['source']}:{item['line']} -> {item['reference']}")

    if args.strict and (report["root_only_scenes"] or builders or missing_resources):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
