# -*- coding: utf-8 -*-
"""为全部待二分 commit 生成变体目录 + shadow.ahk。"""
import os
import subprocess
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))

COMMITS = [
    ("5ad8370", "baseline"),
    ("7351ef5", "boundary"),
    ("40cbd94", "c40cbd94"),
    ("f26e24a", "pre_window"),
    ("c574728", "window"),
    ("4ef2287", "harness"),
    ("d741e8a", "d741e8a"),
    ("8e5202f", "head"),
]


def run(args):
    p = subprocess.run(args, cwd=ROOT, capture_output=True,
                       encoding="utf-8", errors="replace")
    return p.stdout + p.stderr


def main():
    for commit, tag in COMMITS:
        out1 = run([sys.executable, os.path.join(HERE, "make_variant.py"), commit, tag])
        ok1 = "ENTRY=" in out1
        keep = [l for l in out1.splitlines()
                if "lib from" in l or "fallback" in l or "include" in l]
        out2 = run([sys.executable, os.path.join(HERE, "make_shadow.py"), tag])
        ok2 = "SHADOW=" in out2
        print("%-10s %-12s variant=%s shadow=%s" % (commit, tag, ok1, ok2))
        for l in keep:
            print("    " + l.strip())
    return 0


if __name__ == "__main__":
    sys.exit(main())
