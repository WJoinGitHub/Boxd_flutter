#!/usr/bin/env python3
"""Generate assets/l10n/{fr,de,it,es,pt,ja}.json from English strings in app_localizations.dart.

Usage:
  python3 tool/build_locale_assets.py           # all EU/JA locales
  python3 tool/build_locale_assets.py --lang de
  python3 tool/build_locale_assets.py -l fr -l ja

Requires: pip install deep-translator
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DART = ROOT / "lib/l10n/app_localizations.dart"
OUT_DIR = ROOT / "assets" / "l10n"

ALL_LANGS = ("fr", "de", "it", "es", "pt", "ja")


def parse_en_map() -> dict[str, str]:
    text = DART.read_text(encoding="utf-8")
    block = text.split("'en': {", 1)[1].split("'zh':", 1)[0]
    pat = re.compile(r"'(?P<key>[a-z0-9_]+)'\s*:\s*'(?P<val>(?:\\'|[^'])*)'", re.S)
    m: dict[str, str] = {}
    for k, v in pat.findall(block):
        m[k] = v.replace("\\'", "'")
    m["dont_have_account"] = "Don't have an account?"
    m["help_intro"] = (
        "No worries, I'm here to help. Let's work through this together. "
        "Please try the following:"
    )
    return m


def translate_lang(code: str, target: str, base: dict[str, str]) -> None:
    from deep_translator import GoogleTranslator

    tr = GoogleTranslator(source="en", target=target)
    items = list(base.items())
    out: dict[str, str] = {}
    for i, (k, v) in enumerate(items):
        if not v.strip():
            out[k] = v
            continue
        for attempt in range(3):
            try:
                out[k] = tr.translate(v)
                break
            except Exception as e:  # noqa: BLE001
                print(f"[{code}] {k} (try {attempt + 1}): {e}", file=sys.stderr)
                time.sleep(1.2 * (attempt + 1))
        else:
            out[k] = v
        if (i + 1) % 20 == 0:
            print(f"{code}: {i + 1}/{len(items)}")
            time.sleep(0.4)
    out_path = OUT_DIR / f"{code}.json"
    out_path.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {out_path}")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument(
        "-l",
        "--lang",
        action="append",
        choices=list(ALL_LANGS),
        help="Only build these language codes (repeatable). Default: all.",
    )
    args = ap.parse_args()
    langs = args.lang if args.lang else list(ALL_LANGS)

    try:
        from deep_translator import GoogleTranslator  # noqa: F401
    except ImportError:
        print("Install: python3 -m pip install deep-translator", file=sys.stderr)
        sys.exit(1)

    base = parse_en_map()
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    for code in langs:
        translate_lang(code, code, base)


if __name__ == "__main__":
    main()
