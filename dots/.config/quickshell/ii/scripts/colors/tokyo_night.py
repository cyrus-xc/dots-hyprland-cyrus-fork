#!/usr/bin/env python3
"""
Overlay the Tokyo Night palette on top of the generated material colors.

switchwall.sh first runs matugen + generate_colors_material.py seeded with the
Tokyo Night blue, so every template (GTK, Hyprland, fuzzel, KDE...) gets a
matching blue-tinted scheme. This script then replaces the shell colors
(colors.json) and the terminal/material colors (material_colors.scss) with the
exact Tokyo Night values.
"""
import argparse
import json
import re

# https://github.com/folke/tokyonight.nvim (night variant)
MATERIAL = {
    "background": "#1A1B26",
    "on_background": "#C0CAF5",
    "surface": "#1A1B26",
    "surface_dim": "#16161E",
    "surface_bright": "#292E42",
    "surface_container_lowest": "#16161E",
    "surface_container_low": "#1F2335",
    "surface_container": "#24283B",
    "surface_container_high": "#292E42",
    "surface_container_highest": "#343A55",
    "surface_variant": "#292E42",
    "on_surface": "#C0CAF5",
    "on_surface_variant": "#A9B1D6",
    "surface_tint": "#7AA2F7",
    "inverse_surface": "#C0CAF5",
    "inverse_on_surface": "#1A1B26",
    "inverse_primary": "#3D59A1",
    "outline": "#565F89",
    "outline_variant": "#3B4261",
    "shadow": "#000000",
    "scrim": "#000000",
    "primary": "#7AA2F7",
    "on_primary": "#16161E",
    "primary_container": "#3D59A1",
    "on_primary_container": "#C0CAF5",
    "primary_fixed": "#D0DCFF",
    "primary_fixed_dim": "#7AA2F7",
    "on_primary_fixed": "#0B1640",
    "on_primary_fixed_variant": "#3D59A1",
    "secondary": "#BB9AF7",
    "on_secondary": "#16161E",
    "secondary_container": "#283457",
    "on_secondary_container": "#C0CAF5",
    "secondary_fixed": "#E6D9FF",
    "secondary_fixed_dim": "#BB9AF7",
    "on_secondary_fixed": "#24124A",
    "on_secondary_fixed_variant": "#5A3F8F",
    "tertiary": "#7DCFFF",
    "on_tertiary": "#16161E",
    "tertiary_container": "#1F4F68",
    "on_tertiary_container": "#C0CAF5",
    "tertiary_fixed": "#C9ECFF",
    "tertiary_fixed_dim": "#7DCFFF",
    "on_tertiary_fixed": "#00283A",
    "on_tertiary_fixed_variant": "#1F4F68",
    "error": "#F7768E",
    "on_error": "#16161E",
    "error_container": "#4D1F2B",
    "on_error_container": "#FFD3DC",
}

TERMINAL = {
    "term0": "#1A1B26",
    "term1": "#F7768E",
    "term2": "#9ECE6A",
    "term3": "#E0AF68",
    "term4": "#7AA2F7",
    "term5": "#BB9AF7",
    "term6": "#7DCFFF",
    "term7": "#C0CAF5",
    "term8": "#414868",
    "term9": "#F7768E",
    "term10": "#9ECE6A",
    "term11": "#E0AF68",
    "term12": "#7AA2F7",
    "term13": "#BB9AF7",
    "term14": "#7DCFFF",
    "term15": "#C0CAF5",
}

SUCCESS = {
    "success": "#9ECE6A",
    "onSuccess": "#16161E",
    "successContainer": "#2E4A1F",
    "onSuccessContainer": "#D4F0B8",
}


def snake_to_camel(name: str) -> str:
    return re.sub(r"_([a-z])", lambda m: m.group(1).upper(), name)


def patch_scss(path: str) -> None:
    overrides = {snake_to_camel(k): v for k, v in MATERIAL.items()}
    overrides.update(TERMINAL)
    overrides.update(SUCCESS)
    overrides["darkmode"] = "True"

    with open(path) as f:
        lines = f.read().splitlines()

    seen = set()
    out = []
    for line in lines:
        m = re.match(r"^\$([A-Za-z0-9_]+):\s*(.*);$", line)
        if m and m.group(1) in overrides:
            key = m.group(1)
            out.append(f"${key}: {overrides[key]};")
            seen.add(key)
        else:
            out.append(line)
    for key, value in overrides.items():
        if key not in seen:
            out.append(f"${key}: {value};")

    with open(path, "w") as f:
        f.write("\n".join(out) + "\n")


def patch_json(path: str) -> None:
    try:
        with open(path) as f:
            colors = json.load(f)
    except (OSError, json.JSONDecodeError):
        colors = {}
    colors.update(MATERIAL)
    with open(path, "w") as f:
        json.dump(colors, f, indent=2)
        f.write("\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Apply the Tokyo Night palette")
    parser.add_argument("--scss", required=True, help="material_colors.scss to patch")
    parser.add_argument("--json", required=True, help="shell colors.json to patch")
    args = parser.parse_args()
    patch_scss(args.scss)
    patch_json(args.json)
