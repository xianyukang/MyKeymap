package script

import (
	"fmt"
	"github.com/goccy/go-json"
	"os"
	"strings"
)

// 卧槽刚刚发现 GoLand 可以直接把 JSON 字符串粘贴为「 结构体定义 」 一下省掉了好多工作

type Config struct {
	LastEdit string   `json:"lastEdit"`
	Keymaps  []Keymap `json:"keymaps"`
	Options  Options  `json:"options"`
}

type Keymap struct {
	ID       int                 `json:"id"`
	Name     string              `json:"name"`
	Enable   bool                `json:"enable"`
	Hotkey   string              `json:"hotkey"`
	ParentID int                 `json:"parentID"`
	Hotkeys  map[string][]Action `json:"hotkeys"`
}

type Action struct {
	Hotkey        string `json:"hotkey"`
	WindowGroupID int    `json:"windowGroupID"`
	TypeID        int    `json:"actionTypeID"`
	Comment       string `json:"comment"`
	// 下面的字段因动作类型而异
	KeysToSend         string `json:"keysToSend"`
	RemapToKey         string `json:"remapToKey"`
	ValueID            int    `json:"actionValueID"`
	WinTitle           string `json:"winTitle"`
	Target             string `json:"target"`
	Args               string `json:"args"`
	WorkingDir         string `json:"workingDir"`
	RunAsAdmin         bool   `json:"runAsAdmin"`
	DetectHiddenWindow bool   `json:"detectHiddenWindow"`
	AHKCode            string `json:"ahkCode"`
}

var Cfg *Config

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
	Cfg = &config
	return &config, nil
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
