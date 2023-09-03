package script

import (
	"sort"
	"strings"
)

func (c *Config) CapslockAbbr() map[string][]Action {
	for _, km := range c.Keymaps {
		if km.Hotkey == "capslockAbbr" {
			return km.Hotkeys
		}
	}
	return make(map[string][]Action)
}

func (c *Config) SemicolonAbbr() map[string][]Action {
	for _, km := range c.Keymaps {
		if km.Hotkey == "semicolonAbbr" {
			return km.Hotkeys
		}
	}
	return make(map[string][]Action)
}

func (c *Config) CapslockAbbrEnabled() bool {
	for _, km := range c.Keymaps {
		if !km.Enable {
			continue
		}
		for _, actions := range km.Hotkeys {
			for _, a := range actions {
				if a.TypeID == 9 && a.ValueID == 6 {
					return true
				}
			}
		}
	}
	return false
}

func (c *Config) CapslockAbbrKeys() string {
	var keys []string
	for key := range c.CapslockAbbr() {
		keys = append(keys, strings.ReplaceAll(key, ",", ",,"))
	}
	sort.Slice(keys, func(i, j int) bool {
		return keys[i] < keys[j]
	})
	return strings.Join(keys, ",")
}

func (c *Config) SemicolonAbbrEnabled() bool {
	for _, km := range c.Keymaps {
		if !km.Enable {
			continue
		}
		for _, actions := range km.Hotkeys {
			for _, a := range actions {
				if a.TypeID == 9 && a.ValueID == 5 {
					return true
				}
			}
		}
	}
	return false
}

func (c *Config) SemicolonAbbrKeys() string {
	var keys []string
	for key := range c.SemicolonAbbr() {
		keys = append(keys, strings.ReplaceAll(key, ",", ",,"))
	}
	sort.Slice(keys, func(i, j int) bool {
		return keys[i] < keys[j]
	})
	return strings.Join(keys, ",")
}
