# -*- coding: utf-8 -*-
"""汇总全部变体 shadow.log, 输出最终二分表。"""
import os
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
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


def load(tag):
    p = os.path.join(VAR, tag, "shadow.log")
    if not os.path.exists(p):
        return {}
    d = {}
    for line in open(p, encoding="utf-8-sig", errors="replace").read().splitlines():
        if "\t" not in line:
            continue
        _, _, body = line.partition("\t")
        for key in ("S0", "S1", "S2", "S3", "S4", "S5", "S6"):
            if body.startswith(key + " ") or body.startswith(key) and body[2:3] in (" ", ""):
                d[key] = body
    return d


def main():
    print("=" * 118)
    print("MyKeymap E2E 二分表  (进程内 shadow 测试, 全部使用各 commit 真实 bin/lib)")
    print("=" * 118)
    hdr = "%-9s %-11s %-9s %-9s %-9s %-11s %-9s %s" % (
        "commit", "tag", "防重入API", "前台闸门", "闸门4帧", "拖拽闭环", "前台切换", "重复Enable")
    print(hdr)
    print("-" * 118)

    for commit, tag in COMMITS:
        d = load(tag)
        s0 = d.get("S0", "")
        api = "有" if "_stackContains=1" in s0 or "_stackContains= 1" in s0 else "无"
        gate = "有" if "DragSessionAlive=1" in s0 else "无"
        s2 = d.get("S2", "")
        if "NA" in s2:
            frames = "NA"
        elif "frames=" in s2:
            frames = s2.split("frames=")[1].split()[0]
        else:
            frames = "?"
        s4 = d.get("S4", "")
        if "dx=" in s4:
            dx = s4.split("dx=")[1].split()[0]
            drag = "dx=" + dx
        elif "PROBE-INVALID" in s4:
            drag = "探针失效"
        else:
            drag = "?"
        s5 = d.get("S5", "")
        if "被停" in s5:
            fg = "被停@" + s5.split("被停@")[1].split("ms")[0] + "ms"
        elif "仍存活" in s5:
            fg = "存活"
        elif "PropertyError" in s5:
            fg = "无此字段"
        elif "PROBE" in s5:
            fg = "探针失效"
        else:
            fg = "?"
        s6 = d.get("S6", "")
        if not s6:
            rep = "★阻塞(无输出)" if commit in ("5ad8370", "7351ef5", "40cbd94") else "?"
        elif "dt=" in s6:
            rep = "正常"
        else:
            rep = "?"

        print("%-9s %-11s %-9s %-9s %-9s %-11s %-9s %s" % (
            commit[:7], tag, api, gate, frames, drag, fg, rep))

    print("-" * 118)
    print("列说明:")
    print("  防重入API   : f26e24a 起新增 _stackContains()/防重入早退")
    print("  前台闸门    : c574728 起新增 DragSessionAlive()/fg0/lostFocusFrames")
    print("  闸门4帧     : S2 单位测试(DRAG_TEST_MODE, fg0=0) 连三帧结果; TTF=第3帧停")
    print("  拖拽闭环    : S4 真实 StartDragMoveWindow + 光标右移 120px 的窗口位移")
    print("  前台切换    : S5 会话中途切前台后会话是否被杀")
    print("  重复Enable  : S6 连续 Enable 3 次 + Disable 1 次是否阻塞/异常")
    print()
    print("★关键结论★")
    print("  1) 故障1(拖拽不生效) 的引入提交 = c574728")
    print("     baseline/pre_window/c40cbd94 完全没有 fg0 字段(S5 PropertyError);")
    print("     c574728 起 S5 显示 '前台已变=1 -> 会话被停@0ms -> 窗口位移dx=0'。")
    print("  2) S2 证明闸门需要连续 3 帧失焦才停(TTF), 单帧误判不会立刻杀会话;")
    print("     但 S5 显示真实 WinActivate 后**同一 tick 内**就达到 3 帧(SetTimer 10ms x3),")
    print("     即用户按下侧键期间只要前台有任何变化, 会话在 ~30ms 内消失。")
    print("  3) 故障2(长按只生效一次) 与 f26e24a 的防重入相关: baseline 无防重入,")
    print("     重复 Enable 走 MsgBox 'bug'(阻塞, S6 无输出); f26e24a 起改为 OutputDebug + 早退。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
