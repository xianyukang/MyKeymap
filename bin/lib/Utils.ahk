/**
 * 自动关闭的提示窗口 
 * @param message 要提示的文本
 * @param {number} time 超时后关闭
 */
Tip(message, time := -1500) {
  ToolTip(message)
  SetTimer(() => ToolTip(), time)
}

/**
 * 禁用输入法
 * @param hwnd 
 */
DisableIME(hwnd) {
  controlName := ControlGetFocus(hwnd)
  controlHwnd := ControlGetHwnd(controlName)
  DllCall("Imm32\ImmAssociateContext", "ptr", controlHwnd, "ptr", 0, "ptr")
}

/**
 * 获取光标的位置
 * 来源：https://github.com/Ixiko/AHK-libs-and-classes-collection/blob/e5e1666d016c219dc46e7fc97f2bcbf40a9c0da5/AHK_V2/Misc.ahk#L328 GetCaretPos 方法
 * @param X 光标相对于屏幕X轴的位置
 * @param Y 光标相对于屏幕Y轴的位置
 * @param W 光标的宽度
 * @param H 光标的高度
 * @returns {void} 
 */
GetCaretPos(&X?, &Y?, &W?, &H?) {
  ; UIA2 caret
  static IUIA := ComObject("{e22ad333-b25f-460c-83d0-0581107395c9}", "{34723aff-0c9d-49d0-9896-7ab52df8cd8a}")
  try {
    ComCall(8, IUIA, "ptr*", &FocusedEl := 0) ; GetFocusedElement
    ComCall(16, FocusedEl, "int", 10024, "ptr*", &patternObject := 0), ObjRelease(FocusedEl) ; GetCurrentPattern. TextPatternElement2 = 10024
    if patternObject {
      ComCall(10, patternObject, "int*", &IsActive := 1, "ptr*", &caretRange := 0), ObjRelease(patternObject) ; GetCaretRange
      ComCall(10, caretRange, "ptr*", &boundingRects := 0), ObjRelease(caretRange) ; GetBoundingRectangles
      if (Rect := ComValue(0x2005, boundingRects)).MaxIndex() = 3 { ; VT_ARRAY | VT_R8
        X := Round(Rect[0]), Y := Round(Rect[1]), W := Round(Rect[2]), H := Round(Rect[3])
        return
      }
    }
  }

  ; Acc caret
  static _ := DllCall("LoadLibrary", "Str", "oleacc", "Ptr")
  try {
    idObject := 0xFFFFFFF8 ; OBJID_CARET
    if DllCall("oleacc\AccessibleObjectFromWindow", "ptr", WinExist("A"), "uint", idObject &= 0xFFFFFFFF
      , "ptr", -16 + NumPut("int64", idObject == 0xFFFFFFF0 ? 0x46000000000000C0 : 0x719B3800AA000C81, NumPut("int64", idObject == 0xFFFFFFF0 ? 0x0000000000020400 : 0x11CF3C3D618736E0, IID := Buffer(16)))
      , "ptr*", oAcc := ComValue(9, 0)) = 0 {
      x := Buffer(4), y := Buffer(4), w := Buffer(4), h := Buffer(4)
      oAcc.accLocation(ComValue(0x4003, x.ptr, 1), ComValue(0x4003, y.ptr, 1), ComValue(0x4003, w.ptr, 1), ComValue(0x4003, h.ptr, 1), 0)
      X := NumGet(x, 0, "int"), Y := NumGet(y, 0, "int"), W := NumGet(w, 0, "int"), H := NumGet(h, 0, "int")
      if (X | Y) != 0
        return
    }
  }

  ; Default caret
  savedCaret := A_CoordModeCaret, W := 4, H := 20
  CoordMode "Caret", "Screen"
  CaretGetPos(&X, &Y)
  CoordMode "Caret", savedCaret
}