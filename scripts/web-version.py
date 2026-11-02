#!/usr/bin/env python3
"""Writes LiftLog/Web/version.json: which commit the page came from, when, and a checksum for every file.

Run by both builds:
- the GitHub Pages deploy, so the iPhone app can see a newer page is online and download it (live updates);
- the TestFlight build, so the app knows how new the copy inside it is and never swaps it for an older one.

minNative comes from <meta name="liftlog-min-native"> in index.html: the oldest iPhone app (by its NATIVE_API
number in LiftLogApp.swift) the page works with. Bump both when the page starts needing something new from the app.
"""
import hashlib, json, os, re, subprocess, sys

web = sys.argv[1] if len(sys.argv) > 1 else "LiftLog/Web"
out = os.path.join(web, "version.json")


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout.strip()


sha = os.environ.get("GITHUB_SHA") or git("rev-parse", "HEAD")
when = int(git("log", "-1", "--format=%ct", sha))
html = open(os.path.join(web, "index.html"), encoding="utf-8").read()
m = re.search(r'<meta name="liftlog-min-native" content="(\d+)"', html)
files = []
for root, _, names in os.walk(web):
    for n in sorted(names):
        p = os.path.join(root, n)
        rel = os.path.relpath(p, web).replace(os.sep, "/")
        if rel == "version.json" or n.startswith("."):
            continue
        files.append({"path": rel, "sha256": hashlib.sha256(open(p, "rb").read()).hexdigest(),
                      "size": os.path.getsize(p)})
files.sort(key=lambda f: f["path"])
info = {"sha": sha, "time": when, "minNative": int(m.group(1)) if m else 1, "files": files}
with open(out, "w") as f:
    json.dump(info, f, indent=1)
print(f"{out}: {sha[:7]} at {when}, {len(files)} files, minNative {info['minNative']}")
