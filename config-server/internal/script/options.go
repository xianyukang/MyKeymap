package script

type Options struct {
	WindowGroups  []WindowGroup  `json:"windowGroups"`
	Mouse         Mouse          `json:"mouse"`
	Scroll        Scroll         `json:"scroll"`
	PathVariables []PathVariable `json:"pathVariables"`
	Startup       bool           `json:"startup"`
	KeyMapping    string         `json:"keyMapping"`
}

type WindowGroup struct {
	ID            int    `json:"id"`
	Name          string `json:"name"`
	Value         string `json:"value"`
	ConditionType int    `json:"conditionType"`
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
