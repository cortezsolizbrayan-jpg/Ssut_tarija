#!/usr/bin/env python3
"""Fix UTF-8 mojibake in Dart source files."""
from pathlib import Path

REPLACEMENTS = [
    ("C\u00c3\u00b3digo", "C\u00f3digo"),
    ("N\u00c2\u00ba", "N\u00ba"),
    ("Gesti\u00c3\u00b3n", "Gesti\u00f3n"),
    ("Descripci\u00c3\u00b3n", "Descripci\u00f3n"),
    ("Ubicaci\u00c3\u00b3n F\u00c3\u00adsica", "Ubicaci\u00f3n F\u00edsica"),
    ("Informaci\u00c3\u00b3n", "Informaci\u00f3n"),
    ("est\u00c3\u00a1", "est\u00e1"),
    ("versi\u00c3\u00b3n", "versi\u00f3n"),
    ("despu\u00c3\u00a9s", "despu\u00e9s"),
    ("peque\u00c3\u00b1o", "peque\u00f1o"),
    ("r\u00c3\u00a1pidas", "r\u00e1pidas"),
    ("B\u00c3\u00a1sica", "B\u00e1sica"),
    ("Ubicaci\u00c3\u00b3n", "Ubicaci\u00f3n"),
    ("qu\u00c3\u00a9 informaci\u00c3\u00b3n", "qu\u00e9 informaci\u00f3n"),
    ("c\u00c3\u00b3digo", "c\u00f3digo"),
    ("descripci\u00c3\u00b3n", "descripci\u00f3n"),
    ("b\u00c3\u00basqueda", "b\u00fasqueda"),
    ("m\u00c3\u00b3viles", "m\u00f3viles"),
    ("\u00c3\u00a1rea", "\u00e1rea"),
    ("\u00c3\u0081rea", "\u00c1rea"),
    ("\u00c3\u0081", "\u00c1"),
]


def fix_file(path: Path) -> int:
    text = path.read_text(encoding="utf-8")
    original = text
    for bad, good in REPLACEMENTS:
        text = text.replace(bad, good)
    if text != original:
        path.write_text(text, encoding="utf-8", newline="\n")
        return 1
    return 0


def main():
    root = Path(__file__).resolve().parents[1]
    frontend = root / "frontend" / "lib"
    fixed = 0
    for dart in frontend.rglob("*.dart"):
        text = dart.read_text(encoding="utf-8", errors="replace")
        if "\u00c3" in text or "\u00c2" in text:
            if fix_file(dart):
                print(f"fixed: {dart.relative_to(root)}")
                fixed += 1
    print(f"total files fixed: {fixed}")


if __name__ == "__main__":
    main()
