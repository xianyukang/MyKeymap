# -*- coding: utf-8 -*-
"""
决定性验证: 注入的 XButton2 是否让 GetAsyncKeyState 的 0x8000 位(物理按下)置位?

这一条决定故障1的根因方向:
  - 若注入能让 0x8000 置位 -> DragSessionAlive 条件1 在自动化下通过,
    那么 E2E 的 "MOVED" 不能代表真机行为, 故障1 可能是键态闸门误杀;
  - 若注入不能让 0x8000 置位 -> 条件1 首帧就会 StopDragWindow,
    E2E 却仍然 MOVED, 说明拖拽根本没走 Poll 路径, 或被别的机制移动了。

用法: python tools/e2e/probe_keystate.py
"""
import ctypes
import json
import subprocess
import sys
import time

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

HERE = __file__.rsplit("\\", 1)[0]
ROOT = HERE + r"\..\..\.."
ROOT = __import__("os").path.abspath(ROOT)
INJECT = HERE + r"\inject.py"
CNW = 0x08000000

u = ctypes.windll.user32
u.GetAsyncKeyState.argtypes = (ctypes.c_int,)
u.GetAsyncKeyState.restype = ctypes.c_short

VK_XBUTTON2 = 0x06
VK_XBUTTON1 = 0x05
VK_CAPSLOCK = 0x14
VK_A = 0x41


def async_state(vk):
    return u.GetAsyncKeyState(vk) & 0x8000 != 0


def toggled(vk):
    return u.GetKeyState(vk) & 1


def step(label, payload, checks):
    subprocess.run([sys.executable, INJECT, json.dumps(payload)], cwd=ROOT,
                   capture_output=True, creationflags=CNW)
    time.sleep(0.15)
    out = ", ".join("%s=%s" % (n, async_state(v)) for n, v in checks)
    print("  %-28s %s" % (label, out))


print("=== 基线: 无注入 ===")
print("  XButton2 0x8000 =", async_state(VK_XBUTTON2),
      "| CapsLock toggled =", toggled(VK_CAPSLOCK))

print("\n=== 注入 XButton2 down (mouse_event XDOWN) ===")
# down 不 up, 需要单独注入
subprocess.Popen([sys.executable, INJECT, json.dumps([{"act": "xdown", "btn": 2},
                                                      {"act": "sleep", "ms": 900}])],
                 cwd=ROOT, creationflags=CNW)
for i in range(4):
    time.sleep(0.2)
    print("  t=%dms XButton2 0x8000 = %s" % (i * 200, async_state(VK_XBUTTON2)))
time.sleep(1.0)
print("  900ms 后(注入进程已退出): XButton2 0x8000 =", async_state(VK_XBUTTON2))

print("\n=== 注入 CapsLock down/up (带 scan code) ===")
before = toggled(VK_CAPSLOCK)
subprocess.run([sys.executable, INJECT, json.dumps([
    {"act": "keydown", "vk": VK_CAPSLOCK, "sc": 0x3A},
    {"act": "sleep", "ms": 120},
    {"act": "keyup", "vk": VK_CAPSLOCK, "sc": 0x3A}])],
               cwd=ROOT, capture_output=True, creationflags=CNW)
time.sleep(0.2)
print("  CapsLock toggled: before=%s after=%s  (翻转=注入被系统当成真实按键)"
      % (before, toggled(VK_CAPSLOCK)))
print("  CapsLock 0x8000 (松开后应为 False):", async_state(VK_CAPSLOCK))

print("\n=== 注入 a (带 scan code) ===")
subprocess.run([sys.executable, INJECT, json.dumps([
    {"act": "keydown", "vk": VK_A, "sc": 0x1E},
    {"act": "sleep", "ms": 300}])],
               cwd=ROOT, capture_output=True, creationflags=CNW)
time.sleep(0.1)
print("  a 0x8000 (按住期间) =", async_state(VK_A))
time.sleep(0.4)
subprocess.run([sys.executable, INJECT, json.dumps([
    {"act": "keyup", "vk": VK_A, "sc": 0x1E}])],
               cwd=ROOT, capture_output=True, creationflags=CNW)
time.sleep(0.15)
print("  a 0x8000 (松开后)   =", async_state(VK_A))
