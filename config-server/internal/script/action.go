package script

import (
	"fmt"
	"sort"
	"strings"
)

var actionMap = map[int]func(Action, bool) string{
	0: remapKey0,
	1: sendKeys1,
	2: mykeymapActions2,
	3: mouseActions3,
	4: windowActions4,
	5: systemActions5,
	6: launchAppOrActivateWindow6,
	7: builtinFunctions7,
}

func actionToHotkey(action Action) string {
	if f, ok := actionMap[action.TypeID]; ok {
		return f(action, false)
	}
	return ""
}

// TODO 缩写功能中不支持的操作:
// 重映射按键, 锁定当前模式, 暂停重启锁定, 鼠标操作, 窗口操作, ....
// 基本上只支持发送按键, 启动程序, 执行内置函数, 系统控制
func abbrToCode(abbrMap map[string][]Action) string {
	// map 结构转成 list, 然后进行排序
	type Abbr struct {
		abbr    string
		actions []Action
	}
	var abbrList []Abbr
	for abbr, actions := range abbrMap {
		actions = sortActions(actions)
		abbrList = append(abbrList, Abbr{abbr, actions})
	}
	sort.Slice(abbrList, func(i, j int) bool {
		return abbrList[i].abbr < abbrList[j].abbr
	})

	var s strings.Builder
	for _, abbr := range abbrList {
		s.WriteString(fmt.Sprintf("    case \"%s\":\n", abbr.abbr))
		for _, a := range abbr.actions {
			if _, ok := actionMap[a.TypeID]; !ok {
				continue
			}

			call := actionMap[a.TypeID](a, true)
			winTitle, conditionType := Cfg.GetWinTitle(a)
			if conditionType == 5 {
				winTitle = strings.Trim(winTitle, "'")
			}
			if a.WindowGroupID == 0 {
				s.WriteString(fmt.Sprintf("      %s\n", call))
				continue
			}
			s.WriteString(fmt.Sprintf("      if matchWinTitleCondition(%s, %d)\n", winTitle, conditionType))
			s.WriteString(fmt.Sprintf("        %s\n", call))
		}
	}
	return s.String()
}

func sortActions(actions []Action) []Action {
	// 把 a.WindowGroupID 为 0 的放在最后面, 因为这是默认生效的动作, 优先级最低
	res := make([]Action, 0, len(actions))
	var suffix []Action
	for _, a := range actions {
		if a.WindowGroupID == 0 {
			suffix = append(suffix, a)
		} else {
			res = append(res, a)
		}
	}
	res = append(res, suffix...)
	return res
}

func toAHKFuncArg(val string) string {
	prefix := "ahk-expression:"
	if strings.HasPrefix(val, prefix) {
		val = val[len(prefix):]
		return strings.TrimSpace(val)
	}
	return `"` + val + `"`
}

func remapKey0(a Action, inAbbrContext bool) string {
	key := strings.TrimLeft(a.Hotkey, "*")
	ctx := Cfg.GetHotkeyContext(a)
	return fmt.Sprintf(`km.RemapKey("%s", "%s"%s)`, key, a.RemapToKey, ctx)
}

func sendKeys1(a Action, inAbbrContext bool) string {
	keys := toAHKFuncArg(a.KeysToSend)
	if inAbbrContext {
		return fmt.Sprintf(`Send(%s)`, keys)
	}
	ctx := Cfg.GetHotkeyContext(a)
	return fmt.Sprintf(`km.SendKeys("%s", %s%s)`, a.Hotkey, keys, ctx)
}

func mykeymapActions2(a Action, inAbbrContext bool) string {
	ctx := Cfg.GetHotkeyContext(a)
	switch a.ValueID {
	case 0:
		return `km.MapSinglePress(km.ToggleLock)`
	case 1:
		return fmt.Sprintf(`km.Map("%[1]s", _ => EnterCapslockAbbr(capsHook)%s)`, a.Hotkey, ctx)
	case 2:
		return fmt.Sprintf(`km.Map("%[1]s", _ => EnterSemicolonAbbr(semiHook, semiHookAbbrWindow)%s)`, a.Hotkey, ctx)
	default:
		return ""
	}
}

func mouseActions3(a Action, inAbbrContext bool) string {
	winTitle, conditionType := Cfg.GetWinTitle(a)
	ctx := Cfg.GetHotkeyContext(a)
	valueMap := map[int]string{
		0: `km.Map("%[1]s", fast.MoveMouseUp, slow%[2]s), slow.Map("%[1]s", slow.MoveMouseUp%[3]s)`,
		1: `km.Map("%[1]s", fast.MoveMouseDown, slow%[2]s), slow.Map("%[1]s", slow.MoveMouseDown%[3]s)`,
		2: `km.Map("%[1]s", fast.MoveMouseLeft, slow%[2]s), slow.Map("%[1]s", slow.MoveMouseLeft%[3]s)`,
		3: `km.Map("%[1]s", fast.MoveMouseRight, slow%[2]s), slow.Map("%[1]s", slow.MoveMouseRight%[3]s)`,

		4: `km.Map("%[1]s", fast.ScrollWheelUp%s), slow.Map("%[1]s", slow.ScrollWheelUp%s)`,
		5: `km.Map("%[1]s", fast.ScrollWheelDown%s), slow.Map("%[1]s", slow.ScrollWheelDown%s)`,
		6: `km.Map("%[1]s", fast.ScrollWheelLeft%s), slow.Map("%[1]s", slow.ScrollWheelLeft%s)`,
		7: `km.Map("%[1]s", fast.ScrollWheelRight%s), slow.Map("%[1]s", slow.ScrollWheelRight%s)`,

		8:  `km.Map("%[1]s", fast.LButton()%s), slow.Map("%[1]s", slow.LButton()%s)`,
		9:  `km.Map("%[1]s", fast.RButton()%s), slow.Map("%[1]s", slow.RButton()%s)`,
		10: `km.Map("%[1]s", fast.LButtonDown()%s), slow.Map("%[1]s", slow.LButtonDown()%s)`,
		11: `km.Map("%[1]s", fast.LButtonUp()%s), slow.Map("%[1]s", slow.LButtonUp()%s)`,
	}
	if format, ok := valueMap[a.ValueID]; ok {
		if a.ValueID >= 4 {
			return fmt.Sprintf(format, a.Hotkey, ctx)
		}
		fastSuffix := fmt.Sprintf(", %s, %d", winTitle, conditionType)
		slowSuffix := fmt.Sprintf(", , %s, %d", winTitle, conditionType)
		if winTitle == `""` && conditionType == 0 {
			fastSuffix = ""
			slowSuffix = ""
		}
		return fmt.Sprintf(format, a.Hotkey, fastSuffix, slowSuffix)
	}
	return ""
}

func windowActions4(a Action, inAbbrContext bool) string {
	ctx := Cfg.GetHotkeyContext(a)
	valueMap := map[int]string{
		0:  `km.Map("%[1]s", _ => Send("^!{tab}"), taskSwitch%s)`,
		1:  `km.Map("%[1]s", _ => SmartCloseWindow()%s)`,
		2:  `km.Map("%[1]s", _ => SwitchWindows()%s)`,
		3:  `km.Map("%[1]s", _ => CenterAndResizeWindow(1200, 800)%s)`,
		4:  `km.Map("%[1]s", _ => CenterAndResizeWindow(1370, 930)%s)`,
		5:  `km.Map("%[1]s", _ => Send("!{tab}")%s)`,
		6:  `km.Map("%[1]s", _ => Send("#+{right}")%s)`,
		7:  `km.Map("%[1]s", _ => Send("^#{left}")%s)`,
		8:  `km.Map("%[1]s", _ => Send("^#{right}")%s)`,
		9:  `km.Map("%[1]s", _ => WindowMaximize()%s)`,
		10: `km.Map("%[1]s", _ => WindowMinimize()%s)`,
	}
	if format, ok := valueMap[a.ValueID]; ok {
		return fmt.Sprintf(format, a.Hotkey, ctx)
	}
	return ""
}

func systemActions5(a Action, inAbbrContext bool) string {
	callMap := map[int]string{
		0: `ActivateOrRun(, "bin\SoundControl.exe")`,
	}
	if call, ok := callMap[a.ValueID]; ok {
		if inAbbrContext {
			return call
		}
		return fmt.Sprintf(`km.Map("%[1]s", _ => %s%s)`, a.Hotkey, call, Cfg.GetHotkeyContext(a))
	}
	return ""
}

func launchAppOrActivateWindow6(a Action, inAbbrContext bool) string {
	ctx := Cfg.GetHotkeyContext(a)
	winTitle := toAHKFuncArg(a.WinTitle)
	target := toAHKFuncArg(a.Target)
	args := toAHKFuncArg(a.Args)
	workingDir := toAHKFuncArg(a.WorkingDir)

	call := fmt.Sprintf(`ActivateOrRun(%s, %s, %s, %s, %t)`, winTitle, target, args, workingDir, a.Admin)
	if args == `""` && workingDir == `""` && !a.Admin {
		call = fmt.Sprintf(`ActivateOrRun(%s, %s)`, winTitle, target)
	}

	if inAbbrContext {
		return call
	}

	return fmt.Sprintf(`km.Map("%[1]s", _ => %s%s)`, a.Hotkey, call, ctx)
}

func builtinFunctions7(a Action, inAbbrContext bool) string {
	if inAbbrContext {
		return a.AHKCode
	}
	return fmt.Sprintf(`km.Map("%[1]s", _ => %s%s)`, a.Hotkey, a.AHKCode, Cfg.GetHotkeyContext(a))
}
