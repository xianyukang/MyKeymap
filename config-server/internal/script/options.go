package script

type Options struct {
	WindowGroup   []WindowGroup       `json:"windowGroup"`
	CapsAbbr      map[string][]Action `json:"capsAbbr"`
	SemicolonAbbr map[string][]Action `json:"semicolonAbbr"`
}

type WindowGroup struct {
	ID            int    `json:"id"`
	Name          string `json:"name"`
	Value         string `json:"value"`
	ConditionType int    `json:"conditionType"`
}
