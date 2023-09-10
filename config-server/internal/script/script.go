package script

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
	"text/template"
)

func GenerateScripts(config *Config) {
	if err := SaveAHK(config, "./templates/MyKeymap.tmpl", "../bin/MyKeymap.ahk"); err != nil {
		panic(err)
	}
	// if err := SaveAHK(config, "./templates/CustomShellMenu.ahk", "../bin/CustomShellMenu.ahk"); err != nil {
	// 	panic(err)
	// }
}

func SaveAHK(data *Config, templateFile, outputFile string) error {
	Cfg = data
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
	s = strings.ReplaceAll(s, "`", "``")
	s = strings.ReplaceAll(s, "\"", "`\"")
	return `"` + s + `"`
}

func escapeAhkHotkey(key string) string {
	if key == ";" {
		return "`;"
	}
	return key
}

func concat(a, b string) string {
	return a + b
}

func sortHotkeys(hotkeyMap map[string][]Action) []Action {
	res := make([]Action, 0, len(hotkeyMap))
	for hotkey, actions := range hotkeyMap {
		for _, action := range actions {
			// 去掉首末的 " 字符, 虽然此处按字节取子切片也行, 但写法不够通用
			action.Hotkey = substr(toAHKFuncArg(hotkey), 1, -1)
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

// 取子字符串，并不想看起来那么简单: https://stackoverflow.com/a/56129336
// NOTE: this isn't multi-Unicode-codepoint aware, like specifying skintone or
//       gender of an emoji: https://unicode.org/emoji/charts/full-emoji-modifiers.html
func substr(input string, start int, length int) string {
	asRunes := []rune(input)

	if start >= len(asRunes) {
		return ""
	}

	if start+length > len(asRunes) {
		length = len(asRunes) - start
	} else if length < 0 {
		length = len(asRunes) - start + length
	}

	return string(asRunes[start : start+length])
}
