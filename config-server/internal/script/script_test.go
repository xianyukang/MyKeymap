package script

import (
	"strings"
	"testing"
)

func TestSortActions(t *testing.T) {
	a := Action{WindowGroupID: 0, Comment: "item1"}
	b := Action{WindowGroupID: 1, Comment: "item2"}
	c := Action{WindowGroupID: 0, Comment: "item3"}
	s := []Action{a, b, c}
	ss := sortActions(s)
	assertEqual(t, ss[0], b)
	assertEqual(t, ss[1], a)
	assertEqual(t, ss[2], c)
}

func assertEqual[T comparable](t *testing.T, a, b T) {
	t.Helper()
	if a != b {
		t.Errorf("%v != %v", a, b)
	}
}

// 拖拽动作(ValueID 17/18)采用「down/up 成对拦截注册 + SetTimer 轮询」模型:
// - down 热键启动拖拽并记录基准, up 热键结束拖拽 (松开即停)
// - 完全拦截: 不放行原键, 故热键名不得带 "~" 透传前缀
// - 热键名保留用户原配置, 也不得添加 "*" 通配符
func TestWindowActions3DragPollingModel(t *testing.T) {
	Cfg = &Config{}
	cases := map[int]struct {
		hotkey   string
		downCall string
	}{
		17: {hotkey: "XButton2", downCall: "StartDragMoveWindow()"},
		18: {hotkey: "XButton1", downCall: `StartDragResizeWindow("axis")`},
	}
	for valueID, tc := range cases {
		out := windowActions3(Action{TypeID: 3, ValueID: valueID, Hotkey: tc.hotkey}, false)
		// 必须注册拦截版 down 热键 (无 ~ 透传前缀)
		if !strings.Contains(out, `km.Map("`+tc.hotkey+`",`) {
			t.Errorf("valueID %d: expected intercepted down hotkey %q: %s", valueID, tc.hotkey, out)
		}
		// 必须注册拦截版 up 热键 (无 ~ 透传前缀)
		upHotkey := tc.hotkey + " up"
		if !strings.Contains(out, `km.Map("`+upHotkey+`",`) {
			t.Errorf("valueID %d: must register intercepted up hotkey %q: %s", valueID, upHotkey, out)
		}
		// 已否决路线: 不得出现 ~ 透传, 也不得出现 * 通配符
		if strings.Contains(out, "~") {
			t.Errorf("valueID %d: must not use '~' pass-through (rejected route): %s", valueID, out)
		}
		if strings.Contains(out, "*"+tc.hotkey) {
			t.Errorf("valueID %d: must not add '*' wildcard: %s", valueID, out)
		}
		// up 热键必须调用拖拽收尾函数
		if !strings.Contains(out, "StopDragWindow()") {
			t.Errorf("valueID %d: up hotkey must call StopDragWindow(): %s", valueID, out)
		}
		// 必须调用对应的拖拽起始函数
		if !strings.Contains(out, tc.downCall) {
			t.Errorf("valueID %d: expected call %q: %s", valueID, tc.downCall, out)
		}
	}
}
