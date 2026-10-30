# -*- coding: utf-8 -*-
"""
进程级 E2E: 回答"用户按键后, 屏幕上/窗口上到底发生了什么"。

被测: 真实入口脚本(默认 bin\\MyKeymap.ahk)
注入: tools/e2e/inject.py 独立进程 (AHK 会忽略本脚本 Send)
观察:
  - 键盘: tools/e2e/receiver.ahk 焦点 Edit, 逐字符落盘(带 tick)
  - 窗口: GetWindowRect 序列(键盘输入不会移动窗口, 天然免疫真人干扰)

本机约束(全部实测)与对策:
  1) 有真人同时使用机器 -> 裸静默 6s 捕获 72 个非注入按键。判据只能看**目标字符**
     ('[' / ']' , 真人极少输入) 或窗口矩形, 不能看"总字符数"。
  2) zh-CN IME 会把 a 变成"话" -> receiver 侧 ImmAssociateContext(hwnd, 0)。
  3) 有程序每秒抢前台 -> jump(AttachThreadInput + TOPMOST) 后**不 sleep** 立刻注入。
  4) Python 控制台抢前台 -> 注入进程 CREATE_NO_WINDOW。
  5) 偶发丢键 -> 每用例重复 N 次, 取"目标字符最多"的一次。
  6) AHK 反复 Hotkey On/Off 会让第三方 LL 钩子失效 -> 不用自己的钩子做判据。

用法:
  python tools/e2e/run_e2e.py
  python tools/e2e/run_e2e.py --entry <path.ahk> --cases A,A2,B,C,D,E,F --json-out r.json
"""
import argparse
import ctypes
import ctypes.wintypes as w
import json
import os
import re
import subprocess
import sys
import time

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

u = ctypes.windll.user32
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))
AHK = os.path.join(ROOT, "bin", "AutoHotkey64.exe")
OUT = os.path.join(HERE, "out")
INJECT = os.path.join(HERE, "inject.py")
CREATE_NO_WINDOW = 0x08000000

VK_CAPSLOCK = 0x14
VK_Q, VK_E, VK_A = 0x51, 0x45, 0x41

procs = {}


def log(*a):
    print(*a, flush=True)


def kill_all():
    for name in ("AutoHotkey64.exe", "AutoHotkey.exe", "MyKeymap.exe"):
        subprocess.run(["taskkill", "/F", "/IM", name],
                       capture_output=True, text=True)


def wait_file(path, timeout=15.0):
    end = time.time() + timeout
    while time.time() < end:
        if os.path.exists(path):
            try:
                txt = open(path, encoding="utf-8-sig", errors="replace").read()
                if txt.strip():
                    return txt
            except OSError:
                pass
        time.sleep(0.05)
    return None


def start_observer(name):
    procs[name] = subprocess.Popen(
        [AHK, os.path.join(HERE, name)], cwd=ROOT,
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return procs[name]


def start_under_test(entry):
    procs["ut"] = subprocess.Popen(
        [AHK, entry], cwd=os.path.join(ROOT, "bin"),
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    return procs["ut"]


def inject(steps, timeout=90):
    p = subprocess.run([sys.executable, INJECT, json.dumps(steps)], cwd=ROOT,
                       capture_output=True, text=True, timeout=timeout,
                       creationflags=CREATE_NO_WINDOW)
    out = {}
    for line in (p.stdout or "").splitlines():
        if "=" in line:
            k, _, v = line.partition("=")
            out.setdefault(k, []).append(v)
    return out, (p.stdout or "")


def rect_of(hwnd):
    rc = w.RECT()
    if not u.GetWindowRect(hwnd, ctypes.byref(rc)):
        return None
    return rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top


# ─────────────── 键盘观察 ───────────────

def read_chars():
    """返回 [(tick, ch)] — receiver 已按字符粒度落盘。"""
    path = os.path.join(OUT, "receive.log")
    if not os.path.exists(path):
        return []
    rows = []
    for line in open(path, encoding="utf-8-sig", errors="replace").read().splitlines():
        if "\t" not in line:
            continue
        t, _, ch = line.partition("\t")
        if ch == "<RESET>":
            continue
        rows.append((int(t) if t.strip().isdigit() else -1, ch))
    return rows


def reset_receiver():
    ack = os.path.join(OUT, "reset.ack")
    if os.path.exists(ack):
        os.remove(ack)
    with open(os.path.join(OUT, "reset.flag"), "w") as f:
        f.write("1")
    end = time.time() + 3.0
    while time.time() < end:
        if os.path.exists(ack):
            break
        time.sleep(0.02)
    path = os.path.join(OUT, "receive.log")
    for _ in range(40):
        try:
            open(path, "w", encoding="utf-8").close()
            return True
        except OSError:
            time.sleep(0.05)
    return False


def wait_quiet(seconds=1.2, limit=15.0):
    """等桌面安静下来(接收器不再收到新字符)才开始注入, 降低真人输入污染。"""
    end = time.time() + limit
    last_len = len(read_chars())
    stable_since = time.time()
    while time.time() < end:
        time.sleep(0.15)
        cur = len(read_chars())
        if cur != last_len:
            last_len = cur
            stable_since = time.time()
        elif time.time() - stable_since >= seconds:
            return True
    return False


def run_typed(rec_hwnd, steps, repeats=5):
    """重复注入, 返回每次收到的字符序列; 由调用方按目标字符挑最优。"""
    trials = []
    for _ in range(repeats):
        wait_quiet(0.9)
        reset_receiver()
        inject([{"act": "jump", "hwnd": rec_hwnd}] + steps)
        time.sleep(0.55)
        trials.append([ch for _, ch in read_chars()])
    return trials


def _count(trial, target):
    return trial.count(target)


def _pick(trials, target):
    best = max(trials, key=lambda t: _count(t, target))
    return best, _count(best, target)


# ─────────────── 故障2 用例 ───────────────

def case_A(rec_hwnd):
    """按住 CapsLock, 依次按 q,e。真实配置: *q -> '[' , *e -> ']'。"""
    steps = [{"act": "keydown", "vk": VK_CAPSLOCK},
             {"act": "sleep", "ms": 250},
             {"act": "keypress", "vk": VK_Q, "ms": 60},
             {"act": "sleep", "ms": 280},
             {"act": "keypress", "vk": VK_E, "ms": 60},
             {"act": "sleep", "ms": 280},
             {"act": "keyup", "vk": VK_CAPSLOCK},
             {"act": "sleep", "ms": 400}]
    trials = run_typed(rec_hwnd, steps)
    best, n_bracket = _pick(trials, "[")
    _, n_rb = _pick(trials, "]")
    return {"case": "A", "desc": "按住CapsLock 依次按 q,e",
            "expect": "收到 '[' 和 ']'",
            "brackets": n_bracket, "rbrackets": n_rb,
            "best_trial": "".join(best), "trials": ["".join(t) for t in trials],
            "verdict": "OK" if (n_bracket >= 1 and n_rb >= 1) else "BROKEN"}


def case_A2(rec_hwnd):
    """同 A, 但注入 CapsLock 自动重复(每 40ms 一次 down), 复刻真实长按。"""
    steps = [{"act": "keydown", "vk": VK_CAPSLOCK}]
    for _ in range(8):
        steps += [{"act": "sleep", "ms": 40},
                  {"act": "keydown", "vk": VK_CAPSLOCK}]
    steps += [{"act": "sleep", "ms": 150},
              {"act": "keypress", "vk": VK_Q, "ms": 60},
              {"act": "sleep", "ms": 280},
              {"act": "keypress", "vk": VK_E, "ms": 60},
              {"act": "sleep", "ms": 280},
              {"act": "keyup", "vk": VK_CAPSLOCK},
              {"act": "sleep", "ms": 400}]
    trials = run_typed(rec_hwnd, steps)
    best, n_bracket = _pick(trials, "[")
    _, n_rb = _pick(trials, "]")
    return {"case": "A2", "desc": "按住CapsLock(含OS自动重复) 按 q,e",
            "expect": "收到 '[' 和 ']'",
            "brackets": n_bracket, "rbrackets": n_rb,
            "best_trial": "".join(best), "trials": ["".join(t) for t in trials],
            "verdict": "OK" if (n_bracket >= 1 and n_rb >= 1) else "BROKEN"}


def case_B(rec_hwnd):
    """单击 CapsLock 松开, 再单按 a。证明脚本没死(基线可达性)。"""
    steps = [{"act": "keypress", "vk": VK_CAPSLOCK, "ms": 90},
             {"act": "sleep", "ms": 500},
             {"act": "keypress", "vk": VK_A, "ms": 60},
             {"act": "sleep", "ms": 400}]
    trials = run_typed(rec_hwnd, steps)
    best, n_a = _pick(trials, "a")
    return {"case": "B", "desc": "单击CapsLock后单按 a",
            "expect": "收到 'a'", "count_a": n_a,
            "best_trial": "".join(best), "trials": ["".join(t) for t in trials],
            "verdict": "OK" if n_a >= 1 else "BROKEN"}


def case_C(rec_hwnd):
    """3 轮 '按住 CapsLock + q', 每轮都必须有输出(确认不是第一次之后永久失效)。"""
    steps = []
    for _ in range(3):
        steps += [{"act": "keydown", "vk": VK_CAPSLOCK},
                  {"act": "sleep", "ms": 250},
                  {"act": "keypress", "vk": VK_Q, "ms": 60},
                  {"act": "sleep", "ms": 250},
                  {"act": "keyup", "vk": VK_CAPSLOCK},
                  {"act": "sleep", "ms": 450}]
    trials = run_typed(rec_hwnd, steps)
    best, n = _pick(trials, "[")
    return {"case": "C", "desc": "3 轮 (按住CapsLock+q)",
            "expect": "3 个 '['", "brackets": n,
            "best_trial": "".join(best), "trials": ["".join(t) for t in trials],
            "verdict": "OK" if n >= 3 else ("PARTIAL" if n > 0 else "BROKEN")}


# ─────────────── 故障1 用例 ───────────────

def aim(x, y):
    last = ""
    for _ in range(4):
        o, _ = inject([{"act": "move", "x": x, "y": y},
                       {"act": "printcursor"}])
        last = o.get("CURSOR", [""])[0]
        if last == "%d,%d" % (x, y):
            return True, last
        try:
            cx, cy = (int(v) for v in last.split(","))
        except ValueError:
            continue
        if abs(cx - x) <= 2 and abs(cy - y) <= 2:
            return True, last
    return False, last


def drag_once(target_hwnd, fg_hwnd, dx=120, sample=False):
    inject([{"act": "jump", "hwnd": fg_hwnd}])
    r = rect_of(target_hwnd)
    if not r:
        return None, "GetWindowRect 失败"
    seq = [r]
    px, py = r[0] + r[2] // 2, r[1] + r[3] // 2   # 用当前真实矩形重算抓取点
    ok, got = aim(px, py)
    if not ok:
        return seq, "PROBE_INVALID cursor=(%d,%d) got=%s" % (px, py, got)
    steps = [{"act": "xdown", "btn": 2}, {"act": "sleep", "ms": 50}]
    step_px = max(4, dx // 12)
    for _ in range(12):
        steps += [{"act": "movedelta", "dx": step_px, "dy": 0},
                  {"act": "sleep", "ms": 55}]
        if sample:
            steps.append({"act": "printrect", "hwnd": target_hwnd})
    steps += [{"act": "printrect", "hwnd": target_hwnd},
              {"act": "xup", "btn": 2},
              {"act": "sleep", "ms": 250},
              {"act": "printrect", "hwnd": target_hwnd}]
    o, raw = inject(steps)
    for v in o.get("RECT", []):
        if v != "NONE":
            seq.append(tuple(int(x) for x in v.split(",")))
    return seq, raw


def _drag_case(tag, target_hwnd, rec_hwnd, activate, dx=120, repeats=4, sample=False):
    fg = target_hwnd if activate else rec_hwnd
    best = None
    detail = []
    for _ in range(repeats):
        seq, raw = drag_once(target_hwnd, fg, dx=dx, sample=sample)
        if seq is None:
            detail.append(raw)
            continue
        if isinstance(raw, str) and raw.startswith("PROBE_INVALID"):
            detail.append(raw)
            continue
        delta = seq[-1][0] - seq[0][0]
        if best is None or abs(delta) > abs(best[1]):
            best = (seq, delta, raw)
    if best is None:
        return {"case": tag, "probe": "PROBE_INVALID", "detail": detail}
    seq, delta, raw = best
    out = {"case": tag, "activate": activate,
           "before": seq[0], "after": seq[-1], "delta_x": delta,
           "rects": seq, "raw": raw,
           "verdict": "MOVED" if abs(delta) >= 20 else "NO_MOVE"}
    if sample:
        out["rect_x_series"] = [r[0] for r in seq]
        out["distinct_x"] = len(set(r[0] for r in seq))
    return out


def case_D(tgt, rec):
    """目标窗口已激活, 中心按 XButton2 -> 右移 -> 松开。"""
    return _drag_case("D", tgt, rec, activate=True)


def case_E(tgt, rec):
    """目标窗口不激活(接收器做前台), 在目标窗口上拖 XButton2。
    专门验证"前台变化闸门是否误杀"。"""
    return _drag_case("E", tgt, rec, activate=False)


def case_F(tgt, rec):
    """同 E, 逐帧采样 rect, 看是否跟手 / 中途被取消。"""
    return _drag_case("F", tgt, rec, activate=False, sample=True)


# ─────────────── 主流程 ───────────────

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--entry", default=os.path.join(ROOT, "bin", "MyKeymap.ahk"))
    ap.add_argument("--cases", default="A,A2,B,C,D,E,F")
    ap.add_argument("--keep", action="store_true")
    ap.add_argument("--json-out", default="")
    ap.add_argument("--startup-wait", type=float, default=3.0)
    args = ap.parse_args()

    os.makedirs(OUT, exist_ok=True)
    for f in ("receiver.ready", "drag_target.ready", "receive.log",
              "reset.flag", "reset.ack"):
        p = os.path.join(OUT, f)
        if os.path.exists(p):
            os.remove(p)

    kill_all()
    time.sleep(0.4)
    start_observer("receiver.ahk")
    start_observer("drag_target.ahk")
    rtxt = wait_file(os.path.join(OUT, "receiver.ready"))
    dtxt = wait_file(os.path.join(OUT, "drag_target.ready"))
    if not rtxt or not dtxt:
        log("FATAL: observer 未就绪 receiver=%r target=%r" % (rtxt, dtxt))
        kill_all()
        return 2
    rec_hwnd = int(re.search(r"hwnd=(\d+)", rtxt).group(1))
    tgt_hwnd = int(re.search(r"hwnd=(\d+)", dtxt).group(1))
    log("observers: receiver=%d target=%d" % (rec_hwnd, tgt_hwnd))

    # 负向自检: 未启动被测脚本时, 注入 a 必须能收到, 否则整轮数据不可信
    wait_quiet(1.0)
    reset_receiver()
    inject([{"act": "jump", "hwnd": rec_hwnd},
            {"act": "keypress", "vk": VK_A, "ms": 60},
            {"act": "sleep", "ms": 350}])
    time.sleep(0.4)
    chars = [c for _, c in read_chars()]
    # 大小写不敏感: 注入的是 vk=0x41, 若 CapsLock 状态残留或 IME 干预, 落地可能是 'A'
    if "a" not in "".join(chars).lower():
        log("FATAL: 负向自检失败(未启动被测脚本也收不到 'a'), 收到=%r" % "".join(chars))
        kill_all()
        return 4
    log("负向自检通过 (收到 'a')")

    log("under test: %s" % args.entry)
    start_under_test(args.entry)
    time.sleep(args.startup_wait)
    if procs["ut"].poll() is not None:
        log("FATAL: 被测脚本启动即退出 rc=%s" % procs["ut"].returncode)
        kill_all()
        return 3

    wanted = [c.strip() for c in args.cases.split(",") if c.strip()]
    results = []
    for c in wanted:
        log("--- case %s ---" % c)
        try:
            if c == "A":
                r = case_A(rec_hwnd)
            elif c == "A2":
                r = case_A2(rec_hwnd)
            elif c == "B":
                r = case_B(rec_hwnd)
            elif c == "C":
                r = case_C(rec_hwnd)
            elif c == "D":
                r = case_D(tgt_hwnd, rec_hwnd)
            elif c == "E":
                r = case_E(tgt_hwnd, rec_hwnd)
            elif c == "F":
                r = case_F(tgt_hwnd, rec_hwnd)
            else:
                continue
        except subprocess.TimeoutExpired:
            r = {"case": c, "probe": "TIMEOUT"}
        results.append(r)
        brief = {k: v for k, v in r.items()
                 if k not in ("raw", "rects", "rect_x_series")}
        log(json.dumps(brief, ensure_ascii=False))

    if args.json_out:
        with open(args.json_out, "w", encoding="utf-8") as f:
            json.dump(results, f, ensure_ascii=False, indent=2)
        log("json -> %s" % args.json_out)

    if not args.keep:
        kill_all()
    return 0


if __name__ == "__main__":
    sys.exit(main())
