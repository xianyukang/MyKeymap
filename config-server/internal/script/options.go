package script

import (
	"fmt"
	"strings"
)

type Options struct {
	MykeymapVersion string         `json:"mykeymapVersion"`
	WindowGroups    []WindowGroup  `json:"windowGroups"`
	Mouse           Mouse          `json:"mouse"`
	Scroll          Scroll         `json:"scroll"`
	PathVariables   []PathVariable `json:"pathVariables"`
	Startup         bool           `json:"startup"`
	KeyMapping      string         `json:"keyMapping"`
	KeyboardLayout  string         `json:"keyboardLayout"`
}

type WindowGroup struct {
	ID            int    `json:"id"`
	Name          string `json:"name"`
	Value         string `json:"value,omitempty"`
	ConditionType int    `json:"conditionType,omitempty"`
}

type Mouse struct {
	Delay1     string `json:"delay1"`
	Delay2     string `json:"delay2"`
	FastSingle string `json:"fastSingle"`
	FastRepeat string `json:"fastRepeat"`
	SlowSingle string `json:"slowSingle"`
	SlowRepeat string `json:"slowRepeat"`
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

func (c *Config) PathVariables() string {
	var s strings.Builder
	for _, v := range c.Options.PathVariables {
		s.WriteString("  ")
		s.WriteString(v.Name)
		s.WriteString(" := ")
		s.WriteString(toAHKFuncArg(v.Value))
		s.WriteString("\n")
	}
	return s.String()
}

func (c *Config) WindowGroups() string {
	var s strings.Builder
	for _, g := range c.Options.WindowGroups {
		if trimmed := strings.TrimSpace(g.Value); strings.Index(trimmed, "\n") > 0 {
			values := strings.Split(trimmed, "\n")
			for _, v := range values {
				s.WriteString(fmt.Sprintf("  GroupAdd(\"MY_WINDOW_GROUP_%d\", %s)\n", g.ID, toAHKFuncArg(v)))
			}

		}
	}
	return s.String()
}
