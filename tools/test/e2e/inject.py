# -*- coding: utf-8 -*-
"""
E2E 注入端 —— 必须是独立进程。

AHK 会忽略本脚本 Send 产生的键, 所以触发真实热键只能靠跨进程的
SendInput/keybd_event。本脚本用 ctypes 直接调 user32。

用法:
    python tools/e2e/inject.py "<json 数组>"

JSON 每项是一个动作:
    {"act":"keydown",  "vk":0x14}
    {"act":"keyup",    "vk":0x14}
    {"act":"keypress", "vk":0x45, "ms":40}       # down, 等 ms, up
    {"act":"move",     "x":900, "y":420}          # SetCursorPos 绝对坐标
    {"act":"movedelta","dx":12, "dy":0}           # 相对移动(经 mouse_event)
    {"act":"xdown",    "btn":2}                   # 侧键按下 (1=XButton1, 2=XButton2)
    {"act":"xup",      "btn":2}
    {"act":"sleep",    "ms":100}
    {"act":"foreground","hwnd":123456}            # 置前台
    {"act":"printcursor"}                         # 打印当前光标位置
    {"act":"printrect", "hwnd":123456}            # 打印窗口 rect

退出码恒 0; 全部输出打到 stdout, 由主控解析。
"""
import ctypes
import ctypes.wintypes as w
import json
import sys
import time

u = ctypes.windll.user32

MOUSEEVENTF_XDOWN = 0x0080
MOUSEEVENTF_XUP = 0x0100
MOUSEEVENTF_MOVE = 0x0001
XBUTTON1 = 0x0001
XBUTTON2 = 0x0002


class KEYBDINPUT(ctypes.Structure):
    _fields_ = [("wVk", w.WORD), ("wScan", w.WORD), ("dwFlags", w.DWORD),
                ("time", w.DWORD), ("dwExtraInfo", ctypes.POINTER(w.ULONG))]


class MOUSEINPUT(ctypes.Structure):
    _fields_ = [("dx", w.LONG), ("dy", w.LONG), ("mouseData", w.DWORD),
                ("dwFlags", w.DWORD), ("time", w.DWORD),
                ("dwExtraInfo", ctypes.POINTER(w.ULONG))]


class _U(ctypes.Union):
    # x64 下 union 必须按最大成员布局, 否则 cbSize 不符 -> ERROR_INVALID_PARAMETER(87)
    _fields_ = [("ki", KEYBDINPUT), ("mi", MOUSEINPUT)]


class INPUT(ctypes.Structure):
    _anonymous_ = ("u",)
    _fields_ = [("type", w.DWORD), ("u", _U)]


def _send(inp):
    n = u.SendInput(1, ctypes.byref(inp), ctypes.sizeof(INPUT))
    if n != 1:
        print("SENDINPUT_FAILED err=%d" % ctypes.GetLastError())


def key(vk, up=False, sc=0):
    """
    sc 必须传真实扫描码, 否则:
      - AHK 的 hotkey 匹配在某些路径上依赖 sc
      - 注入的 CapsLock 会被系统当成"无扫描码"事件, 行为与物理按键不同
    实测: 不带 sc 注入 CapsLock 会导致系统 CapsLock 状态意外翻转。
    """
    inp = INPUT(type=1)
    inp.u.ki = KEYBDINPUT(vk, sc, 0x0002 if up else 0, 0, None)
    _send(inp)


def xbutton(btn, up=False):
    data = XBUTTON1 if btn == 1 else XBUTTON2
    flags = MOUSEEVENTF_XUP if up else MOUSEEVENTF_XDOWN
    inp = INPUT(type=0)
    inp.u.mi = MOUSEINPUT(0, 0, data, flags, 0, None)
    _send(inp)


def cursor():
    pt = w.POINT()
    u.GetCursorPos(ctypes.byref(pt))
    return pt.x, pt.y


def rect(hwnd):
    rc = w.RECT()
    if not u.GetWindowRect(hwnd, ctypes.byref(rc)):
        return None
    return rc.left, rc.top, rc.right - rc.left, rc.bottom - rc.top


def do(spec):
    for step in spec:
        act = step["act"]
        if act == "keydown":
            key(step["vk"], False, step.get("sc", 0))
        elif act == "keyup":
            key(step["vk"], True, step.get("sc", 0))
        elif act == "keypress":
            key(step["vk"], False, step.get("sc", 0))
            time.sleep(step.get("ms", 40) / 1000.0)
            key(step["vk"], True, step.get("sc", 0))
        elif act == "move":
            u.SetCursorPos(step["x"], step["y"])
        elif act == "click":
            inp = INPUT(type=0)
            inp.u.mi = MOUSEINPUT(0, 0, 0, 0x0002, 0, None)   # LEFTDOWN
            _send(inp)
            time.sleep(step.get("ms", 40) / 1000.0)
            inp = INPUT(type=0)
            inp.u.mi = MOUSEINPUT(0, 0, 0, 0x0004, 0, None)   # LEFTUP
            _send(inp)
        elif act == "movedelta":
            inp = INPUT(type=0)
            inp.u.mi = MOUSEINPUT(step["dx"], step["dy"], 0,
                                  MOUSEEVENTF_MOVE, 0, None)
            _send(inp)
        elif act == "xdown":
            xbutton(step["btn"], False)
        elif act == "xup":
            xbutton(step["btn"], True)
        elif act == "sleep":
            time.sleep(step["ms"] / 1000.0)
        elif act == "foreground":
            h = step["hwnd"]
            u.ShowWindow(h, 9)          # SW_RESTORE
            u.SetForegroundWindow(h)
            time.sleep(0.05)
            print("FG_ACTUAL=%d FG_WANT=%d" % (u.GetForegroundWindow(), h))
        elif act == "jump":
            # 强隔离置前台: AttachThreadInput 解锁 + TOPMOST, 然后**不 sleep**
            # 直接开始后续按键。本机有程序每秒抢前台, 中间停 250ms 就必定被抢走。
            h = step["hwnd"]
            k32 = ctypes.windll.kernel32
            fg = u.GetForegroundWindow()
            cur = k32.GetCurrentThreadId()
            fgtid = u.GetWindowThreadProcessId(fg, None) if fg else 0
            att = False
            if fgtid and fgtid != cur:
                att = bool(u.AttachThreadInput(cur, fgtid, True))
            try:
                u.ShowWindow(h, 9)
                u.SetWindowPos(h, -1, 0, 0, 0, 0, 0x0001 | 0x0002 | 0x0040)  # TOPMOST|NOSIZE|NOMOVE|SHOW
                u.BringWindowToTop(h)
                u.SetForegroundWindow(h)
                u.SetFocus(h)
            finally:
                if att:
                    u.AttachThreadInput(cur, fgtid, False)
            print("JUMP_ACTUAL=%d JUMP_WANT=%d" % (u.GetForegroundWindow(), h))
        elif act == "printcursor":
            x, y = cursor()
            print("CURSOR=%d,%d" % (x, y))
        elif act == "printrect":
            r = rect(step["hwnd"])
            print("RECT=%s" % (",".join(str(v) for v in r) if r else "NONE"))
        else:
            print("UNKNOWN_STEP=%s" % act)


if __name__ == "__main__":
    spec = json.loads(sys.argv[1])
    do(spec)
    print("INJECT_DONE")
