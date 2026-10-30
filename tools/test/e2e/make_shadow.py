# -*- coding: utf-8 -*-
"""
为变体目录生成进程内 shadow 测试脚本 shadow.ahk。

为什么需要: 桌面 E2E 在本机不可靠(真人操作 / IME / 抢前台 / AHK 钩子重排)。
进程内测试用**该 commit 真实的 bin/lib**, 用真实 Action/KeymapManager API 驱动,
只观察它们自己的状态与窗口矩形, 因此对每个 commit 可做同样的实验 -> 可二分。

测试项(全部带能力探测, 旧版缺 API 就跳过而不是报错):
  S0  能力探测
  S1  Activate 防重入: 栈 [Global,A,B] 时再 Activate(A)
  S2  前台闸门(单位): DRAG_TEST_MODE=true, fg0=0 -> 连续帧是否 3 帧内变 F
  S3  前台稳定(单位): DRAG_TEST_MODE=true, fg0=当前前台 -> 应持续 T
  S4  拖拽闭环: StartDragMoveWindow + 光标右移 120px -> 窗口是否跟随
  S5  拖拽+前台变化: 会话中途 WinActivate 别的窗口 -> 会话是否被杀
  S6  重复 Enable/Disable: 自动重复场景下会不会阻塞(MsgBox)或状态错乱
  S7  按住触发键多次 Activate 后, 子 keymap 的热键是否仍存活(故障2 机制)
"""
import os
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
except Exception:
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(HERE)))

TMPL = r'''#Requires AutoHotkey v2.0
#SingleInstance Force
#Warn All, Off

#Include bin\lib\translation.ahk
#Include bin\lib\Functions.ahk
#Include bin\lib\Actions.ahk
#Include bin\lib\KeymapManager.ahk
#Include bin\lib\InputTipWindow.ahk
#Include bin\lib\Utils.ahk
#Include bin\lib\Midi.ahk

global OUT := A_ScriptDir "\shadow.log"
try FileDelete(OUT)

Log(s) {
  global OUT
  try FileAppend(A_TickCount "`t" s "`n", OUT, "UTF-8")
}

HasFunc(name) {
  try {
    fn := %name%
    return IsObject(fn)
  } catch {
    return false
  }
}

HasVar(name) {
  try {
    v := %name%
    return 1
  } catch {
    return 0
  }
}

Rect(hwnd) {
  rc := Buffer(16, 0)
  DllCall("GetWindowRect", "ptr", hwnd, "ptr", rc)
  return [NumGet(rc, 0, "int"), NumGet(rc, 4, "int")
        , NumGet(rc, 8, "int") - NumGet(rc, 0, "int")
        , NumGet(rc, 12, "int") - NumGet(rc, 4, "int")]
}

Aim(x, y) {
  Loop 4 {
    DllCall("SetCursorPos", "int", x, "int", y)
    Sleep 30
    pt := Buffer(8, 0)
    DllCall("GetCursorPos", "ptr", pt)
    cx := NumGet(pt, 0, "int"), cy := NumGet(pt, 4, "int")
    if (Abs(cx - x) <= 2 && Abs(cy - y) <= 2)
      return true
  }
  return false
}

MakeWin(title, x, y) {
  g := Gui("+AlwaysOnTop", title)
  g.AddText("w300 h100", "shadow target")
  g.Show("x" x " y" y " w340 h140")
  return g
}

; ── S0 能力探测 ──
S0() {
  Log("S0 DragSessionAlive=" HasFunc("DragSessionAlive")
    . " _stackContains=" HasFunc("_stackContains")
    . " StopDragWindowForKey=" HasFunc("StopDragWindowForKey")
    . " StartDragMoveWindow=" HasFunc("StartDragMoveWindow")
    . " DRAG_TEST_MODE=" HasVar("DRAG_TEST_MODE")
    . " DRAG_HARD_TIMEOUT_MS=" HasVar("DRAG_HARD_TIMEOUT_MS")
    . " DRAG_LOSTFOCUS_FRAMES=" HasVar("DRAG_LOSTFOCUS_FRAMES")
    . " KeymapWaitRelease=" HasFunc("KeymapWaitRelease"))
}

; ── S1 Activate 防重入 ──
S1() {
  kmA := Keymap("A", "F13", "*F13", 0)
  kmB := Keymap("B", "F14", "*F14", 0)
  KeymapManager.Stack.Push(kmA)
  KeymapManager.Stack.Push(kmB)
  n0 := KeymapManager.Stack.Length
  t0 := A_TickCount
  try
    KeymapManager.Activate(kmA)
  catch as e
    Log("S1 抛错 " Type(e) ": " e.Message)
  dt := A_TickCount - t0
  Log("S1 n0=" n0 " n1=" KeymapManager.Stack.Length " dt=" dt "ms"
    . " 二次入栈=" (KeymapManager.Stack.Length > n0 ? "YES(未早退)" : "NO(早退/被挡)"))
  while KeymapManager.Stack.Length > 1
    KeymapManager.Stack.Pop()
}

; ── S2 前台变化闸门(单位) ──
S2() {
  global WindowDragState, DRAG_TEST_MODE
  if !HasFunc("DragSessionAlive") {
    Log("S2 NA(无 DragSessionAlive)")
    return
  }
  DRAG_TEST_MODE := true
  st := {mode:"move", hwnd:0, key:"XButton2", mx0:0, my0:0, x0:0, y0:0,
         w0:0, h0:0, ox:0, oy:0, lx:0, ly:0, lw:0, lh:0, moved:false,
         t0:A_TickCount, fg0:0, lostFocusFrames:0}
  WindowDragState := st
  a := DragSessionAlive(st)
  b := DragSessionAlive(st)
  c := DragSessionAlive(st)
  Log("S2 frames=" (a?"T":"F") (b?"T":"F") (c?"T":"F")
    . " lostFrames=" st.lostFocusFrames
    . " state=" (WindowDragState ? "残留" : "已清空"))
  try StopDragWindowForKey("")
  DRAG_TEST_MODE := false
}

; ── S3 前台稳定(单位) ──
S3() {
  global WindowDragState, DRAG_TEST_MODE
  if !HasFunc("DragSessionAlive") {
    Log("S3 NA(无 DragSessionAlive)")
    return
  }
  DRAG_TEST_MODE := true
  st := {mode:"move", hwnd:0, key:"XButton2", mx0:0, my0:0, x0:0, y0:0,
         w0:0, h0:0, ox:0, oy:0, lx:0, ly:0, lw:0, lh:0, moved:false,
         t0:A_TickCount, fg0:DllCall("GetForegroundWindow","ptr"),
         lostFocusFrames:0}
  WindowDragState := st
  a := DragSessionAlive(st)
  b := DragSessionAlive(st)
  c := DragSessionAlive(st)
  Log("S3 frames=" (a?"T":"F") (b?"T":"F") (c?"T":"F"))
  try StopDragWindowForKey("")
  DRAG_TEST_MODE := false
}

; ── S4 拖拽闭环 ──
S4() {
  global WindowDragState, DRAG_TEST_MODE
  if !HasFunc("StartDragMoveWindow") {
    Log("S4 NA(无 StartDragMoveWindow)")
    return
  }
  DRAG_TEST_MODE := true
  g := MakeWin("SHADOW_T1", 700, 300)
  Sleep 400
  r0 := Rect(g.Hwnd)
  cx := r0[1] + r0[3] // 2, cy := r0[2] + r0[4] // 2
  if !Aim(cx, cy) {
    Log("S4 PROBE-INVALID 光标无法落到 (" cx "," cy ")")
    try g.Destroy()
    DRAG_TEST_MODE := false
    return
  }
  wfp := DllCall("WindowFromPoint", "int64", (cy << 32) | (cx & 0xFFFFFFFF), "ptr")
  root := wfp ? DllCall("GetAncestor", "ptr", wfp, "uint", 2, "ptr") : 0
  try StartDragMoveWindow()
  Sleep 150
  st := WindowDragState
  if !st {
    Log("S4 会话未建立 命中=" (root = g.Hwnd))
    try g.Destroy()
    DRAG_TEST_MODE := false
    return
  }
  Aim(cx + 120, cy)
  Sleep 400
  r1 := Rect(g.Hwnd)
  Log("S4 命中=" (root = g.Hwnd) " 会话hwnd=" (st.hwnd = g.Hwnd)
    . " x0=" r0[1] " x1=" r1[1] " dx=" (r1[1] - r0[1])
    . " movedFlag=" (st.moved ? 1 : 0)
    . " 会话存活=" (WindowDragState ? 1 : 0))
  try StopDragWindowForKey("")
  try g.Destroy()
  DRAG_TEST_MODE := false
}

; ── S5 拖拽时前台变化 ──
S5() {
  global WindowDragState, DRAG_TEST_MODE
  if !HasFunc("StartDragMoveWindow") {
    Log("S5 NA(无 StartDragMoveWindow)")
    return
  }
  DRAG_TEST_MODE := true
  g := MakeWin("SHADOW_T2", 700, 480)
  Sleep 400
  r0 := Rect(g.Hwnd)
  cx := r0[1] + r0[3] // 2, cy := r0[2] + r0[4] // 2
  if !Aim(cx, cy) {
    Log("S5 PROBE-INVALID")
    try g.Destroy()
    DRAG_TEST_MODE := false
    return
  }
  try StartDragMoveWindow()
  Sleep 150
  st := WindowDragState
  if !st {
    Log("S5 会话未建立(无可用的 fg0 字段 = 该版本无前台闸门)")
    try g.Destroy()
    DRAG_TEST_MODE := false
    return
  }
  hasFg0 := true
  fg0 := 0
  try
    fg0 := st.fg0
  catch
    hasFg0 := false
  if !hasFg0 {
    Log("S5 会话对象无 fg0 字段 -> 该版本没有前台变化闸门")
    try StopDragWindowForKey("")
    try g.Destroy()
    DRAG_TEST_MODE := false
    return
  }
  g2 := MakeWin("SHADOW_T3", 1080, 480)
  WinActivate("SHADOW_T3")
  Sleep 60
  fg1 := DllCall("GetForegroundWindow", "ptr")
  diedAt := -1
  t0 := A_TickCount
  Loop 60 {
    if !WindowDragState {
      diedAt := A_TickCount - t0
      break
    }
    Sleep 10
  }
  r1 := Rect(g.Hwnd)
  Log("S5 fg0=" fg0 " fg1=" fg1 " 前台已变=" (fg0 != fg1)
    . " 会话" (diedAt >= 0 ? "被停@" diedAt "ms" : "仍存活(60帧)")
    . " 窗口位移dx=" (r1[1] - r0[1]))
  try StopDragWindowForKey("")
  try g.Destroy()
  try g2.Destroy()
  DRAG_TEST_MODE := false
}

; ── S6 重复 Enable/Disable(自动重复场景) ──
S6() {
  km := Keymap("S6", "F15", "*F15", 0)
  km.Map("*F15", (*) => 0)
  km.Enable(false)
  km.Enable(false)
  km.Enable(false)
  t0 := A_TickCount
  km.Disable()
  dt := A_TickCount - t0
  Log("S6 Enable3+Disable1 dt=" dt "ms (若此处无输出=>被 MsgBox 阻塞)")
  try km.Disable()
}

; ── S7 按住触发键多次 Activate 后热键是否还活着(故障2 核心) ──
; 机制假设: 每次 Activate 都会 Push+Enable 同一个 keymap, 于是同一物理热键
;   被 Enable 了 N 次; 收尾只 Disable 一次 => Hotkey("Off") 把热键关掉,
;   但"另一层"仍认为自己 enabled。之后按键不再被接住 => 用户看到"只生效一次"。
; 判据: 反复 Activate 后, 用 GetKeyState 无法判断; 改为直接读 keymap 的
;   每个 _Hotkey.enabled 标志, 并尝试 EnableHotkey 看是否命中 "已 enabled" 分支。
S7() {
  km := Keymap("S7", "F16", "*F16", 0)
  km.Map("*F16", (*) => 0)
  names := []
  for n in km.M
    names.Push(n)
  Log("S7 热键名=" (names.Length ? names[1] : "(空)") " 条目数=" names.Length)
  hks := km.M.Has(names[1]) ? km.M[names[1]] : []
  Log("S7 初始 同物理热键实例数=" hks.Length)
  km.Enable(false)
  en1 := hks.Length ? (hks[1].enabled ? 1 : 0) : -1
  Log("S7 Enable 后 enabled=" en1)
  ; 模拟自动重复: 再 Enable 两次(基线版没有任何防护)
  try km.Enable(false)
  try km.Enable(false)
  Log("S7 重复 Enable 完成(未阻塞)")
  km.Disable()
  en2 := hks.Length ? (hks[1].enabled ? 1 : 0) : -1
  Log("S7 Disable 后 enabled=" en2 " (期望 0; 若仍 1 则状态错乱)")
  ; Disable 之后热键是否还能被启用(真实可用性)
  ok := true
  try
    km.EnableHotkey(names[1])
  catch
    ok := false
  Log("S7 Disable 后再 EnableHotkey 成功=" (ok ? 1 : 0))
  try km.Disable()
}

for fn in ["S0", "S1", "S2", "S3", "S4", "S5", "S6", "S7"] {
  try
    %fn%()
  catch as e
    Log(fn " EX " Type(e) ": " e.Message)
}
Log("DONE")
ExitApp 0
'''


def main():
    variant = sys.argv[1]
    dest = os.path.join(ROOT, "_e2e_variants", variant)
    if not os.path.isdir(os.path.join(dest, "bin", "lib")):
        print("缺少 %s" % dest)
        return 2
    path = os.path.join(dest, "shadow.ahk")
    with open(path, "w", encoding="utf-8-sig", newline="\r\n") as f:
        f.write(TMPL)
    print("SHADOW=%s" % path)
    return 0


if __name__ == "__main__":
    sys.exit(main())
