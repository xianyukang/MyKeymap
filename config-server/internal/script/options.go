package script

import (
	"fmt"
	"strings"
)

type Options struct {
	HideMatrix       bool             `json:"hideMatrix"`
	MykeymapVersion  string           `json:"mykeymapVersion"`
	WindowGroups     []WindowGroup    `json:"windowGroups"`
	Mouse            Mouse            `json:"mouse"`
	Scroll           Scroll           `json:"scroll"`
	CommandInputSkin CommandInputSkin `json:"commandInputSkin"`
	PathVariables    []PathVariable   `json:"pathVariables"`
	Startup          bool             `json:"startup"`
	Language         string           `json:"language"`
	KeyMapping       string           `json:"keyMapping"`
	KeyboardLayout   string           `json:"keyboardLayout"`
}

type WindowGroup struct {
	ID            int    `json:"id"`
	Name          string `json:"name"`
	Value         string `json:"value,omitempty"`
	ConditionType int    `json:"conditionType,omitempty"`
}

type Mouse struct {
	KeepMouseMode bool   `json:"keepMouseMode"`
	ShowTip       bool   `json:"showTip"`
	TipSymbol     string `json:"tipSymbol"`
	Delay1        string `json:"delay1"`
	Delay2        string `json:"delay2"`
	FastSingle    string `json:"fastSingle"`
	FastRepeat    string `json:"fastRepeat"`
	SlowSingle    string `json:"slowSingle"`
	SlowRepeat    string `json:"slowRepeat"`
}
type Scroll struct {
	Delay1        string `json:"delay1"`
	Delay2        string `json:"delay2"`
	OnceLineCount string `json:"onceLineCount"`
}
type PathVariable struct {
	Name  string `json:"name"`
	Value string `json:"value"`
}

type CommandInputSkin struct {
	BackgroundColor       string `json:"backgroundColor"`
	BackgroundOpacity     string `json:"backgroundOpacity"`
	BorderWidth           string `json:"borderWidth"`
	BorderColor           string `json:"borderColor"`
	BorderOpacity         string `json:"borderOpacity"`
	BorderRadius          string `json:"borderRadius"`
	CornerColor           string `json:"cornerColor"`
	CornerOpacity         string `json:"cornerOpacity"`
	GridlineColor         string `json:"gridlineColor"`
	GridlineOpacity       string `json:"gridlineOpacity"`
	KeyColor              string `json:"keyColor"`
	KeyOpacity            string `json:"keyOpacity"`
	HideAnimationDuration string `json:"hideAnimationDuration"`
	WindowYPos            string `json:"windowYPos"`
	WindowWidth           string `json:"windowWidth"`
	WindowShadowColor     string `json:"windowShadowColor"`
	WindowShadowOpacity   string `json:"windowShadowOpacity"`
	WindowShadowSize      string `json:"windowShadowSize"`
}

func (c *Config) PathVariables() string {
	var s strings.Builder
	for _, v := range c.Options.PathVariables {
		if strings.TrimSpace(v.Name) == "" {
			continue
		}
		s.WriteString("  ")
		s.WriteString(v.Name)
		s.WriteString(" := ")
		s.WriteString(toAHKFuncArg(v.Value))
		s.WriteString("\n")
	}
	return s.String()
}

func notBlankLines(str string) []string {
	var res []string
	for _, line := range strings.Split(str, "\n") {
		line = strings.TrimSpace(line)
		if line != "" {
			res = append(res, line)
		}
	}
	return res
}

func (c *Config) WindowGroups() string {
	var s strings.Builder
	for _, g := range c.Options.WindowGroups {
		addGroup(&s, g.Value, g.ID)
	}
	for _, km := range c.Keymaps {
		addGroup(&s, km.DisableAt, km.ID, "GROUP_DISABLE_KEYMAP_")
	}
	return s.String()
}

func (c *Config) getKeymapDisableAt(kmID int) string {
	for _, km := range c.Keymaps {
		if km.ID == kmID {
			lines := notBlankLines(km.DisableAt)
			switch {
			case len(lines) == 0:
				return ""
			case len(lines) == 1:
				return lines[0]
			case len(lines) > 1:
				return fmt.Sprintf("ahk_group GROUP_DISABLE_KEYMAP_%d", kmID)
			}
		}
	}
	return ""
}

func addGroup(s *strings.Builder, value string, id int, prefix ...string) {
	if lines := notBlankLines(value); len(lines) > 1 {
		for _, v := range lines {
			arg := toAHKFuncArg(v)
			if arg != `""` {
				s.WriteString(fmt.Sprintf("  GroupAdd(\"%s\", %s)\n", groupName(id, prefix...), arg))
			}
		}

	}
}
