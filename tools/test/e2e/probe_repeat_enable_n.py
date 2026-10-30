# -*- coding: utf-8 -*-
"""
对"重复 Enable 是否被 MsgBox 阻塞"做多次采样, 每变体跑 5 次, 统计阻塞次数。
单次结果会受 MsgBox 弹出时机/自动化 MessageFilter 影响, 必须多次取频次。
"""
import os
import subprocess
import sys
import time

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
AHK = os.path.join(ROOT, "bin", "AutoHotkey64.exe")
VAR = os.path.join(ROOT, "_e2e_variants")

CASES = [
    ("5ad8370", "baseline"),
    ("7351ef5", "boundary"),
    ("40cbd94", "c40cbd94"),
    ("f26e24a", "pre_window"),
    ("c574728", "window"),
    ("8e5202f", "head"),
]
N = 5


def kill_all():
    for n in ("AutoHotkey64.exe", "AutoHotkey.exe", "MyKeymap.exe"):
        subprocess.run(["taskkill", "/F", "/IM", n], capture_output=True)


def one(d, logp):
    if os.path.exists(logp):
        os.remove(logp)
    p = subprocess.Popen([AHK, os.path.join(d, "rep.ahk")], cwd=d,
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    done = False
    for _ in range(100):
        if os.path.exists(logp):
            try:
                if "DONE" in open(logp, encoding="utf-8-sig",
                                  errors="replace").read():
                    done = True
                    break
            except OSError:
                pass
        if p.poll() is not None:
            break
        time.sleep(0.05)
    killed = p.poll() is None
    if killed:
        p.kill()
    time.sleep(0.1)
    kill_all()
    return done


def main():
    print("%-9s %-11s %-16s %s" % ("commit", "tag", "阻塞次数/总次数", "结论"))
    print("-" * 84)
    for commit, tag in CASES:
        d = os.path.join(VAR, tag)
        logp = os.path.join(d, "rep.log")
        if not os.path.exists(os.path.join(d, "rep.ahk")):
            print("%-9s %-11s (缺少 rep.ahk)" % (commit, tag))
            continue
        blocked = 0
        for _ in range(N):
            kill_all()
            time.sleep(0.25)
            if not one(d, logp):
                blocked += 1
        verdict = "可复现阻塞" if blocked == N else (
            "不稳定" if blocked else "从不阻塞")
        print("%-9s %-11s %-16s %s" % (commit, tag, "%d/%d" % (blocked, N), verdict))

    kill_all()
    return 0


if __name__ == "__main__":
    sys.exit(main())
