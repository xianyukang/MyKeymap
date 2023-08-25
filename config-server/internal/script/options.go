package script

type Options struct {
	WindowGroups []WindowGroup `json:"windowGroups"`
}

type WindowGroup struct {
	ID            int    `json:"id"`
	Name          string `json:"name"`
	Value         string `json:"value"`
	ConditionType int    `json:"conditionType"`
}
