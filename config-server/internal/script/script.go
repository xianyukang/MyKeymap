package script

import (
	"crypto/md5"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/template"
	"unicode"
)

func GenerateScripts(config *Config) {
	// 把分应用配置转成一个函数
	// TODO
	// perAppConfigToFunction(config)

	if err := SaveAHK(config, "./templates/script2.ahk", "../bin/MyKeymap.ahk"); err != nil {
		panic(err)
	}
	if err := SaveAHK(config, "./templates/CustomShellMenu.ahk", "../bin/CustomShellMenu.ahk"); err != nil {
		panic(err)
	}
}

type obj = map[string]interface{}

type item struct {
	Key    string
	Value  string
	Prefix string
}

func SaveAHK(data *Config, templateFile, outputFile string) error {
	files := []string{
		templateFile,
	}

	ts, err := template.New(filepath.Base(templateFile)).Funcs(TemplateFuncMap).ParseFiles(files...)
	if err != nil {
		return err
	}

	// 用 Go 代码生成 AHK 脚本时会使用 \n 导致换行符不统一
	// 先输出到一个字符串, 然后对换行符进行统一, 把 \n 改成 \r\n
	builder := new(strings.Builder)
	err = ts.Execute(builder, data)
	if err != nil {
		return err
	}
	res := builder.String()
	res = strings.ReplaceAll(res, "\r\n", "\n")
	res = strings.ReplaceAll(res, "\n", "\r\n")

	f, err := os.Create(outputFile)
	if err != nil {
		return err
	}
	//goland:noinspection GoUnhandledErrorResult
	defer f.Close()

	// 因为模板文件就是 UTF-8 with BOM,  所以输出文件也是 UTF-8 with BOM
	// _, _ = f.Write([]byte{0xef, 0xbb, 0xbf}) // 写入 utf-8 的 BOM (0xefbbbf)
	_, err = f.Write([]byte(res))
	return err
}

var TemplateFuncMap = template.FuncMap{
	"contains":        strings.Contains,
	"toList":          toList,
	"concat":          concat,
	"join":            join,
	"ahkString":       ahkString,
	"escapeAhkHotkey": escapeAhkHotkey,
	"actionToHotkey":  actionToHotkey,
	"abbrToCode":      abbrToCode,
	"sortHotkeys":     sortHotkeys,
}

func join(sep string, elems []interface{}) string {
	elems2 := make([]string, 0)
	for _, val := range elems {
		elems2 = append(elems2, val.(string))
	}
	return strings.Join(elems2, sep)
}

func ahkString(s string) string {
	s = strings.ReplaceAll(s, `"`, `""`)
	return `"` + s + `"`
}

func escapeAhkHotkey(key string) string {
	if key == ";" {
		return "`;"
	}
	return key
}

func toList(keymap obj) []item {
	res := make([]item, 0) // 指定切片大小是一个危险的行为,  说不定就搞出来很多空结构体...

	for key, keyConfig := range keymap {
		keyConfig := keyConfig.(obj)
		v := keyConfig["value"].(string)
		p, _ := keyConfig["prefix"].(string)
		if len(v) > 0 {
			res = append(res, item{
				Key:    key,
				Value:  v,
				Prefix: p,
			})
		}
	}

	sort.Slice(res, func(i, j int) bool {
		if res[i].Value == res[j].Value {
			return res[i].Key < res[j].Key
		}
		return res[i].Value < res[j].Value
	})

	return res
}

func concat(a, b string) string {
	return a + b
}

func perAppConfigToFunction(config map[string]interface{}) {

	allAhkFuncs := make([]interface{}, 0)

	// 加上全局生效这个 window selector
	windowSelectors := config["windowSelectors"].([]interface{})
	windowSelectors = append(windowSelectors, obj{
		"id":        "2",
		"value":     "USELESS",
		"groupName": "USELESS",
		"groupCode": "USELESS",
	})

	// 遍历每一个模式的每一个键的配置,  使用类型断言解析 json 确实挺麻烦的
	otherInfo := config["otherInfo"].(obj)
	keymapNames := otherInfo["KEYMAP_PLUS_ABBR"].([]interface{})

	// 依次获取 keymap、keyName、keyConfig 等变量
	for _, keymapName := range keymapNames {
		keymapName := keymapName.(string)
		keymap := config[keymapName].(obj)
		for keyName, _ := range keymap {
			keyConfig := keymap[keyName].(obj)

			if len(keyConfig) == 1 {
				// 如果按键没有分应用配置, 往上提一层: { "A": { 2: config } } -> { "A": config }
				keymap[keyName] = keyConfig["2"]
			} else {
				// 如果按键有分应用配置,  则转成一个函数
				funcName, funcDefinition := keyConfigToAhkFunc(keyConfig, keymapName, windowSelectors)
				if len(funcDefinition) > 0 {
					keymap[keyName].(obj)["value"] = funcName + "()"
					keymap[keyName].(obj)["prefix"] = "*"
					keymap[keyName].(obj)["type"] = "function"
					allAhkFuncs = append(allAhkFuncs, funcDefinition)
				} else {
					keymap[keyName].(obj)["value"] = ""
				}
			}
		}
	}
	sort.Slice(allAhkFuncs, func(i, j int) bool {
		return allAhkFuncs[i].(string) < allAhkFuncs[j].(string)
	})
	config["all_ahk_funcs"] = allAhkFuncs
}

func keyConfigToAhkFunc(keyConfig obj, keymapName string, windowSelectors []interface{}) (string, string) {

	branches := make([]string, 0)
	for _, sel := range windowSelectors {
		sel := sel.(obj)
		selId := sel["id"].(string)
		groupName := sel["groupName"].(string)
		groupCode := sel["groupCode"].(string)
		if len(groupCode) == 0 {
			continue
		}
		config, ok := keyConfig[selId]
		if ok {
			config := config.(obj)
			value := config["value"].(string)
			if len(value) > 0 {
				branches = append(branches, ifBranch(selId, "ahk_group "+groupName, value))
			}
		}
	}
	body := strings.Join(branches, "\n")
	funcName := fmt.Sprintf("%s__%s", keymapName, MD5(body))
	funcDefinition := fmt.Sprintf("%s()\n{\n%s\n}", funcName, body)
	if len(body) == 0 {
		funcDefinition = ""
	}
	return funcName, funcDefinition
}

func ifBranch(selId, selValue, value string) string {
	value = strings.TrimLeft(value, "\n")
	value = strings.TrimRight(value, " ")
	value = strings.TrimRight(value, "\n")

	lines := strings.Split(value, "\n")
	lines2 := make([]string, 0)
	for _, line := range lines {
		if len(line) > 0 {
			lines2 = append(lines2, "        "+strings.TrimLeftFunc(line, unicode.IsSpace))
		}
	}
	value = strings.Join(lines2, "\n")
	if selId == "2" {
		return fmt.Sprintf("    if (true) {\n%s\n        return\n    }", value)
	}
	return fmt.Sprintf("    if winactive(\"%s\") {\n%s\n        return\n    }", selValue, value)

}

func MD5(text string) string {
	data := []byte(text)
	return fmt.Sprintf("%x", md5.Sum(data))
}

func sortHotkeys(hotkeyMap map[string][]Action) []Action {
	res := make([]Action, 0, len(hotkeyMap))
	for hotkey, actions := range hotkeyMap {
		for _, action := range actions {
			action.Hotkey = hotkey
			res = append(res, action)
		}
	}

	sort.Slice(res, func(i, j int) bool {
		// 先根据 action type 排, 然后根据 hotkey 的长度和字典序来排序
		if res[i].TypeID != res[j].TypeID {
			return res[i].TypeID < res[j].TypeID
		}

		if len(res[i].Hotkey) != len(res[j].Hotkey) {
			return len(res[i].Hotkey) < len(res[j].Hotkey)
		}

		return res[i].Hotkey < res[j].Hotkey
	})

	return res
}
