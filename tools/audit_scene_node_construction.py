#!/usr/bin/env python3
"""Audit Godot scene files for scene-tree structure built imperatively in GDScript.

This is a static audit helper, not a replacement for opening scenes in Godot 4.6.1.
It intentionally reports candidates for human review; dynamic gameplay objects such as
short-lived effects may be valid, while persistent level structure should live in .tscn.
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCENE_NODE_RE = re.compile(r'^\[node name="([^"]+)" type="([^"]+)"(?: parent="([^"]*)")?', re.M)
EXT_SCRIPT_RE = re.compile(r'^\[ext_resource[^\n]*path="res://([^"]+\.gd)"[^\n]*id="([^"]+)"', re.M)
ROOT_SCRIPT_RE = re.compile(r'^script\s*=\s*ExtResource\("([^"]+)"\)', re.M)
NODE_NEW_RE = re.compile(
    r'\b(Node2D|Node|Area2D|StaticBody2D|CharacterBody2D|RigidBody2D|'
    r'CollisionShape2D|CollisionPolygon2D|Marker2D|Control|CanvasLayer|Camera2D|'
    r'Label|RichTextLabel|ColorRect|Sprite2D|AnimatedSprite2D|TileMapLayer|'
    r'ProgressBar|Button|PanelContainer|VBoxContainer|HBoxContainer|Polygon2D)\.new\s*\('
)
ADD_CHILD_RE = re.compile(r'\b(?:\w+\.)?add_child\s*\(')
SCENE_INSTANTIATE_RE = re.compile(r'\b(?:\w+\.)?instantiate\s*\(')
SCRIPT_REF_RE = re.compile(r'res://[^"\'\s)]+')
FUNCTION_RE = re.compile(r'^func\s+([A-Za-z0-9_]+)\s*\(', re.M)


def read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except (OSError, UnicodeError):
        return ""


def attached_script(scene_text: str) -> str | None:
    resources = {rid: path for path, rid in EXT_SCRIPT_RE.findall(scene_text)}
    root = scene_text.splitlines()
    root_seen = False
    root_script_id = None
    for line in root:
        if line.startswith("[node "):
            if not root_seen:
                root_seen = True
            else:
                continue
        if root_seen and line.startswith("script = ExtResource("):
            match = ROOT_SCRIPT_RE.match(line)
            if match:
                root_script_id = match.group(1)
            break
    rel = resources.get(root_script_id or "")
    return str(ROOT / rel) if rel else None


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--strict", action="store_true",
                        help="exit non-zero when a scene-attached script creates nodes imperatively")
    parser.add_argument("--json", action="store_true", help="emit machine-readable JSON")
    args = parser.parse_args()

    scenes = sorted((ROOT / "scenes").rglob("*.tscn"))
    scripts = sorted((ROOT / "scripts").rglob("*.gd"))
    scene_rows = []
    violation_rows = []
    script_rows = []

    for path in scenes:
        text = read_text(path)
        nodes = SCENE_NODE_RE.findall(text)
        attached = attached_script(text)
        attached_text = read_text(Path(attached)) if attached else ""
        constructors = NODE_NEW_RE.findall(attached_text)
        add_child_count = len(ADD_CHILD_RE.findall(attached_text))
        instantiate_count = len(SCENE_INSTANTIATE_RE.findall(attached_text))
        row = {
            "scene": path.relative_to(ROOT).as_posix(),
            "node_count": len(nodes),
            "root": nodes[0][0] if nodes else None,
            "root_type": nodes[0][1] if nodes else None,
            "attached_script": Path(attached).relative_to(ROOT).as_posix() if attached else None,
            "script_bytes": len(attached_text.encode("utf-8")),
            "node_new_count": len(constructors),
            "add_child_count": add_child_count,
            "instantiate_count": instantiate_count,
        }
        scene_rows.append(row)
        if attached and (constructors or add_child_count):
            violation_rows.append(row)

    for path in scripts:
        text = read_text(path)
        funcs = FUNCTION_RE.findall(text)
        script_rows.append({
            "script": path.relative_to(ROOT).as_posix(),
            "bytes": len(text.encode("utf-8")),
            "lines": len(text.splitlines()),
            "functions": len(funcs),
            "node_new_count": len(NODE_NEW_RE.findall(text)),
            "add_child_count": len(ADD_CHILD_RE.findall(text)),
            "scene_instantiate_count": len(SCENE_INSTANTIATE_RE.findall(text)),
        })

    duplicate_groups = {}
    for path in [*scenes, *scripts]:
        text = read_text(path)
        if text:
            import hashlib
            duplicate_groups.setdefault(hashlib.sha256(text.encode("utf-8")).hexdigest(), []).append(
                path.relative_to(ROOT).as_posix()
            )
    duplicates = [group for group in duplicate_groups.values() if len(group) > 1]
    largest_scripts = sorted(script_rows, key=lambda x: x["bytes"], reverse=True)[:20]

    if args.json:
        import json
        print(json.dumps({
            "scene_count": len(scenes),
            "script_count": len(scripts),
            "scenes_with_imperative_construction_in_attached_script": violation_rows,
            "largest_scripts": largest_scripts,
            "exact_duplicate_text_groups": duplicates,
        }, ensure_ascii=False, indent=2))
    else:
        print(f"[SCENE AUDIT] scenes={len(scenes)} scripts={len(scripts)}")
        print("[SCENE AUDIT] attached scripts that call Node.new() / add_child():")
        for row in sorted(violation_rows, key=lambda x: (x["node_new_count"] + x["add_child_count"]), reverse=True):
            print("  - {scene}: nodes={node_count}, script={attached_script}, "
                  "Node.new={node_new_count}, add_child={add_child_count}, "
                  "PackedScene.instantiate={instantiate_count}".format(**row))
        print("[SCENE AUDIT] largest scripts:")
        for row in largest_scripts:
            print("  - {script}: {bytes} bytes, {lines} lines, {functions} functions".format(**row))
        print("[SCENE AUDIT] exact duplicate text groups:")
        for group in duplicates:
            print("  - " + " == ".join(group))
        print("[SCENE AUDIT] Review candidates only: dynamic effects and data-driven instances may be legitimate.")
    if args.strict and violation_rows:
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
