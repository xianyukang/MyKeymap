# -*- coding: utf-8 -*-
"""
对全部变体跑 shadow.ahk(进程内, 不碰桌面), 输出 S1/S2/S3 结论对比表。

S1 = Activate 防重入: 栈 [Global,A,B] 时再 Activate(A) 是否二次入栈
S2 = 前台变化闸门: fg0 != 前台 时会话第几帧被停
S3 = 前台稳定: fg0 == 前台 时会话是否持续存活
"""
import os
import subprocess
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
AHK = os.path.join(ROOT, "bin", "AutoHotkey64.exe")
VAR = os.path.join(ROOT, "_e2e_variants")

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


def run_shadow(tag):
    d = os.path.join(VAR, tag)
    script = os.path.join(d, "shadow.ahk")
    log = os.path.join(d, "shadow.log")
    if os.path.exists(log):
        os.remove(log)
    try:
        p = subprocess.run([AHK, script], cwd=d, capture_output=True,
                           timeout=120, creationflags=0x08000000)
    except subprocess.TimeoutExpired:
        return {"tag": tag, "timeout": True, "lines": []}
    lines = []
    if os.path.exists(log):
        lines = [l.split("\t", 1)[1] if "\t" in l else l
                 for l in open(log, encoding="utf-8-sig",
                               errors="replace").read().splitlines() if l.strip()]
    return {"tag": tag, "timeout": False, "lines": lines,
            "rc": p.returncode}


def pick(lines, prefix):
    for l in lines:
        if l.startswith(prefix):
            return l
    return "(未记录)"


def main():
    print("%-10s %-12s %-52s %-30s %s" %
          ("commit", "tag", "S1 防重入", "S2 前台变化闸门", "S3 前台稳定"))
    print("-" * 150)
    rows = []
    for commit, tag in COMMITS:
        r = run_shadow(tag)
        if r.get("timeout"):
            print("%-10s %-12s TIMEOUT" % (commit, tag))
            continue
        s1 = pick(r["lines"], "S1 stackAfter")
        s2 = pick(r["lines"], "S2 frames")
        s3 = pick(r["lines"], "S3 frames")
        s1s = s1.replace("S1 stackAfter=", "").split(" 二次")[0]
        s1v = "早退" if "NO(早退)" in s1 else ("未早退" if "YES(未早退)" in s1 else "?")
        s2v = s2.replace("S2 frames=", "").replace(" stateAfter=", " state=")
        s3v = s3.replace("S3 frames=", "")
        print("%-10s %-12s %-52s %-30s %s"
              % (commit, tag, "二次入栈=%s (%s)" % (s1v, s1s), s2v, s3v))
        rows.append((commit, tag, s1, s2, s3))

    print("\n--- 明细 ---")
    for commit, tag, s1, s2, s3 in rows:
        print("\n[%s %s]" % (commit, tag))
        for l in (s1, s2, s3):
            print("   " + l)
    return 0


if __name__ == "__main__":
    sys.exit(main())
