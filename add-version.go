package main

import (
	"encoding/json"
	"fmt"
	"os"
	"strings"
)

func main() {
	oldVersion, newVersion := getVersion()

	// However, the notation [n] immediately before the verb indicates that the nth one-indexed argument is to be formatted instead.
	tasks := []struct {
		path   string
		format string
	}{
		{"readme.md", `[MyKeymap %s](https://xianyukang.com/MyKeymap.html`},
		{"config-back\\templates\\script2.ahk", `Menu, Tray, Tip, MyKeymap %s by 咸鱼阿康`},
		{"config-front\\src\\App.vue", `<v-list-item-subtitle> version: %s </v-list-item-subtitle>`},
		{"D:\\project\\my_site\\docs\\MyKeymap.md", `下载地址: [MyKeymap %[1]s](https://static.xianyukang.com/MyKeymap-%[1]s.7z)`},
	}

	for _, t := range tasks {
		replaceInFile(t.path, fmt.Sprintf(t.format, oldVersion), fmt.Sprintf(t.format, newVersion))
	}

	// MyKeymap.ahk 本身就是 utf-8 with BOM, replaceInFile 并不会改变文件本身的编码
	path := "bin\\MyKeymap.ahk"
	format := `Menu, Tray, Tip, MyKeymap %s by 咸鱼阿康`
	replaceInFile(path, fmt.Sprintf(format, oldVersion), fmt.Sprintf(format, newVersion))
}

func replaceInFile(path, old, new string) {
	content := readFileAsString(path)
	// 前三个字节是 utf-8 的 BOM: ef bb bf
	// fmt.Printf("%x %x %x\n", content[0], content[1], content[2])
	newContent := strings.ReplaceAll(content, old, new)
	err := os.WriteFile(path, []byte(newContent), 0644)
	if err != nil {
		panic(err)
	}
}

func readFileAsString(path string) string {
	bytes, err := os.ReadFile(path)
	if err != nil {
		panic(err)
	}
	return string(bytes) // 仅仅把这一串字节视为 string, 并不涉及字符串编解码哦!
}

func getVersion() (string, string) {
	var j struct {
		Version struct {
			Major int `json:"major"`
			Minor int `json:"minor"`
			Patch int `json:"patch"`
		} `json:"version"`
	}

	bytes, err := os.ReadFile("build.json")
	if err != nil {
		panic(err)
	}

	err = json.Unmarshal(bytes, &j)
	if err != nil {
		panic(err)
	}

	return fmt.Sprintf("%d.%d.%d", j.Version.Major, j.Version.Minor, j.Version.Patch),
		fmt.Sprintf("%d.%d.%d", j.Version.Major, j.Version.Minor, j.Version.Patch+1)
}
