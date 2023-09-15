package script

import (
	"bytes"
	"fmt"
	"github.com/goccy/go-json"
	"os"
	"sort"
	"strings"
)

// 卧槽刚刚发现 GoLand 可以直接把 JSON 字符串粘贴为「 结构体定义 」 一下省掉了好多工作

type Config struct {
	Keymaps    []Keymap `json:"keymaps,omitempty"`
	Options    Options  `json:"options,omitempty"`
	KeyMapping string   `json:"-"`
}

type Keymap struct {
	ID       int                 `json:"id"`
	Name     string              `json:"name"`
	Enable   bool                `json:"enable"`
	Hotkey   string              `json:"hotkey"`
	ParentID int                 `json:"parentID"`
	Delay    int                 `json:"delay"`
	Hotkeys  map[string][]Action `json:"hotkeys"`
}

type Action struct {
	WindowGroupID int    `json:"windowGroupID"`
	TypeID        int    `json:"actionTypeID"`
	Comment       string `json:"comment,omitempty"`
	Hotkey        string `json:"hotkey,omitempty"`
	// 下面的字段因动作类型而异
	KeysToSend         string `json:"keysToSend,omitempty"`
	RemapToKey         string `json:"remapToKey,omitempty"`
	ValueID            int    `json:"actionValueID,omitempty"`
	WinTitle           string `json:"winTitle,omitempty"`
	Target             string `json:"target,omitempty"`
	Args               string `json:"args,omitempty"`
	WorkingDir         string `json:"workingDir,omitempty"`
	RunAsAdmin         bool   `json:"runAsAdmin,omitempty"`
	RunInBackground    bool   `json:"runInBackground,omitempty"`
	DetectHiddenWindow bool   `json:"detectHiddenWindow,omitempty"`
	AHKCode            string `json:"ahkCode,omitempty"`

	RemapInHotIf bool `json:"-"`
}

func ParseConfig(file string) (*Config, error) {
	data, err := os.ReadFile(file)
	if err != nil {
		return nil, fmt.Errorf("cannot read file %s: %v", file, err)
	}

	var config Config
	err = json.Unmarshal(data, &config)
	if err != nil {
		return nil, fmt.Errorf("cannot parse config: %v", err)
	}

	if config.Options.Mouse.TipSymbol == "" {
		config.Options.Mouse.TipSymbol = "🐶"
	}
	if config.Options.CommandInputSkin == (CommandInputSkin{}) {
		config.Options.CommandInputSkin = CommandInputSkin{
			BackgroundColor:       "#FFFFFF",
			BackgroundOpacity:     "0.9",
			BorderWidth:           "3",
			BorderColor:           "#FFFFFF",
			BorderOpacity:         "1.0",
			BorderRadius:          "10",
			CornerColor:           "#000000",
			CornerOpacity:         "0.0",
			GridlineColor:         "#2843AD",
			GridlineOpacity:       "0.04",
			KeyColor:              "#000000",
			KeyOpacity:            "1.0",
			HideAnimationDuration: "0.34",
			WindowYPos:            "0.25",
			WindowWidth:           "700",
			WindowShadowColor:     "#000000",
			WindowShadowOpacity:   "0.5",
			WindowShadowSize:      "3.0",
		}
	}

	return &config, nil
}

func SaveConfigFile(config *Config) {
	// 先写到缓冲区,  如果直接写文件的话, 当编码过程遇到错误时, 会导致文件损坏
	buf := new(bytes.Buffer)
	encoder := json.NewEncoder(buf)
	encoder.SetIndent("", "  ")
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(config); err != nil {
		panic(err)
	}

	if err := os.WriteFile("../data/config.json", buf.Bytes(), 0644); err != nil {
		panic(err)
	}
}

func (c *Config) GetWinTitle(a Action) (winTitle string, conditionType int) {
	if a.WindowGroupID == 0 {
		return `""`, 0
	}

	for _, g := range c.Options.WindowGroups {
		if g.ID == a.WindowGroupID {
			if g.ConditionType == 5 {
				return fmt.Sprintf(`'%s'`, g.Value), 5
			}

			v := strings.TrimSpace(g.Value)
			if strings.Index(v, "\n") >= 0 {
				return fmt.Sprintf(`"ahk_group MY_WINDOW_GROUP_%d"`, g.ID), g.ConditionType
			}
			return fmt.Sprintf(`"%s"`, v), g.ConditionType
		}
	}
	return `""`, 0
}

func (c *Config) GetHotkeyContext(a Action) string {
	winTitle, conditionType := c.GetWinTitle(a)
	if winTitle == `""` && conditionType == 0 {
		return ""
	}
	return fmt.Sprintf(", , %s, %d", winTitle, conditionType)
}

func (c *Config) EnabledKeymaps() []Keymap {
	var enabled []Keymap
	for _, km := range c.Keymaps {
		if km.ID == 1 && km.Enable {
			c.handleKeyRemapping(km)
			enabled = append(enabled, km)
		}
		if km.ID >= 5 && km.Enable {
			enabled = append(enabled, km)
		}
	}

	// 对模式进行分组和排序
	groups := make(map[int][]Keymap)
	for _, km := range enabled {
		if km.ParentID != 0 {
			groups[km.ParentID] = append(groups[km.ParentID], km)
		}
	}
	var res []Keymap
	for _, km := range enabled {
		if km.ParentID == 0 {
			res = append(res, km)
			if subKeymaps, ok := groups[km.ID]; ok {
				res = append(res, subKeymaps...)
			}
		}
	}
	return res
}

func (c *Config) handleKeyRemapping(custom Keymap) {
	// 把自定义热键中的按键重映射取出来, 这部分需要单独渲染
	var list []Action
	for hk, actions := range custom.Hotkeys {
		for i, a := range actions {
			if a.TypeID == remapKey {
				a.Hotkey = hk
				list = append(list, a)
				a.RemapInHotIf = true
				actions[i] = a
			}
		}
	}

	// 按照 windowGroupID 进行排序
	sort.SliceStable(list, func(i, j int) bool {
		return list[i].WindowGroupID < list[j].WindowGroupID
	})

	var s strings.Builder
	lastGroup := -2233
	for _, a := range list {
		if lastGroup != a.WindowGroupID {
			s.WriteString("\n")
			s.WriteString(hotifHeader(c, a))
			s.WriteString("\n")
			lastGroup = a.WindowGroupID
		}
		s.WriteString(fmt.Sprintf("%s::%s\n", strings.TrimLeft(a.Hotkey, "*"), a.RemapToKey))
	}
	s.WriteString("\n#HotIf")
	c.KeyMapping = s.String()
}

func hotifHeader(c *Config, a Action) string {
	winTitle, conditionType := c.GetWinTitle(a)
	if winTitle == `""` && conditionType == 0 {
		return "#HotIf"
	}
	switch conditionType {
	case 1:
		return fmt.Sprintf("#HotIf WinActive(%s)", winTitle)
	case 2:
		return fmt.Sprintf("#HotIf WinExist(%s)", winTitle)
	case 3:
		return fmt.Sprintf("#HotIf !WinActive(%s)", winTitle)
	case 4:
		return fmt.Sprintf("#HotIf !WinExist(%s)", winTitle)
	case 5:
		return fmt.Sprintf("#HotIf %s ", winTitle)
	}
	return ""
}
