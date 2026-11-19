#!/usr/bin/env python3
"""Write a 301 redirect into firebase.json for every legacy page in web/pages.

/privacy-policy.html  and  /privacy-policy  ->  /pages/privacy-policy.html

Only redirects this script generated (destination /pages/*.html) are replaced;
any redirect you add by hand (e.g. short links like /doctor) is kept.
"""
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
PAGES = ROOT / "web" / "pages"
CONFIG = ROOT / "firebase.json"
PREFIX = "/pages/"

config = json.loads(CONFIG.read_text())
hosting = config["hosting"]
manual = [r for r in hosting.get("redirects", []) if not (r["destination"].startswith(PREFIX) and r["destination"].endswith(".html"))]

generated = []
for page in sorted(PAGES.rglob("*.html")):
    rel = page.relative_to(PAGES).as_posix()
    if rel in ("index.html", "404.html"):  # "/" is the Flutter app; 404 is ours
        continue
    dest = PREFIX + rel
    old = "/" + rel
    generated.append({"source": old, "destination": dest, "type": 301})
    generated.append({"source": old[: -len(".html")], "destination": dest, "type": 301})

hosting["redirects"] = manual + generated
CONFIG.write_text(json.dumps(config, indent=2) + "\n")
print(f"firebase.json: {len(generated) // 2} legacy page redirect(s) written.")
