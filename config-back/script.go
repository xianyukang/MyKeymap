package main

import (
	"crypto/md5"
	"fmt"
	"os"
	"sort"
	"strings"
	"text/template"
	"unicode"
)

func generateScript(data obj) {
	// 把分应用配置转成一个函数
	perAppConfigToFunction(data)

	// 鼠标的慢速移动, 筛选出鼠标操作,  然后把函数名中的 fast 替换为 slow
	SlowMoveMode := make(map[string]interface{})
	for key, keyConfig := range data[data["Settings"].(obj)["MouseMoveMode"].(string)].(obj) {
		keyConfig := keyConfig.(obj)
		t := keyConfig["type"].(string)
		v := keyConfig["value"].(string)
		if len(v) > 0 && t == "鼠标操作" {
			value := strings.Replace(v, "fast", "slow", 1)
			prefix, _ := keyConfig["prefix"].(string)
			SlowMoveMode[key] = map[string]interface{}{
				"value":  value,
				"prefix": prefix,
			}
		}
	}
	data["MouseMoveMode"] = SlowMoveMode

	saveMyKeymapAhk(data)
}

type obj = map[string]interface{}

type item struct {
	Key    string
	Value  string
	Prefix string
}

func saveMyKeymapAhk(data obj) {

	f, err := os.Create("../bin/MyKeymap.ahk")
	if err != nil {
		panic(err)
	}
	defer func(f *os.File) {
		_ = f.Close()
	}(f)

	files := []string{
		"./templates/script2.ahk",
	}

	ts, err := template.New("script2.ahk").Funcs(templateFuncMap).ParseFiles(files...)
	if err != nil {
		panic(err)
	}

	// 先输出到一个字符串, 然后对换行符进行统一, 把 \n 改成 \r\n
	builder := new(strings.Builder)
	err = ts.Execute(builder, data)
	if err != nil {
		panic(err)
	}
	res := builder.String()
	res = strings.ReplaceAll(res, "\r\n", "\n")
	res = strings.ReplaceAll(res, "\n", "\r\n")

	// 先写入 utf-8 的 BOM (0xefbbbf)
	// (唉,  golang 还是不如 python 方便,  还得自己处理 BOM、CRLF 之类的问题
	_, _ = f.Write([]byte{0xef, 0xbb, 0xbf})
	_, _ = f.Write([]byte(res))
}

var templateFuncMap = template.FuncMap{
	"contains":        strings.Contains,
	"toList":          toList,
	"concat":          concat,
	"join":            join,
	"ahkString":       ahkString,
	"escapeAhkHotkey": escapeAhkHotkey,
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
		"id":    "2",
		"value": "USELESS",
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
		selValue := sel["value"].(string)
		config, ok := keyConfig[selId]
		if ok {
			config := config.(obj)
			value := config["value"].(string)
			if len(value) > 0 {
				branches = append(branches, ifBranch(selId, selValue, value))
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
