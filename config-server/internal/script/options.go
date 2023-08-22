package script

type Options struct {
	WindowGroups  []WindowGroup       `json:"windowGroups"`
	CapslockAbbr  map[string][]Action `json:"capslockAbbr"`
	SemicolonAbbr map[string][]Action `json:"semicolonAbbr"`
}

type WindowGroup struct {
	ID            int    `json:"id"`
	Name          string `json:"name"`
	Value         string `json:"value"`
	ConditionType int    `json:"conditionType"`
}
