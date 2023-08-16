package main

import (
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"text/template"
)

var commandMap = map[string]func(){
	"AlignText": AlignText,
}

func AlignText() {
	text, err := readStdin()
	if err != nil {
		fmt.Println(err)
		return
	}
	r := strings.NewReplacer("`", "\\`", "\\", "\\\\")
	data := map[string]interface{}{
		"Text": r.Replace(text),
	}
	executeTemplate(data, "./html-tools/AlignText.tmpl.html", "./html-tools/AlignText.html")
}

func readStdin() (string, error) {
	fi, _ := os.Stdin.Stat()
	if (fi.Mode() & os.ModeCharDevice) == 0 {
		// 这个分支表示 stdin 的数据来自管道
	} else {
		return "", errors.New("需要从管道读取数据")
	}

	bytes, err := ioutil.ReadAll(os.Stdin)
	if err != nil {
		return "", err
	}
	// CRLF 转换
	r := string(bytes)
	if strings.Index(r, "\r\n") != -1 {
		r = strings.ReplaceAll(r, "\r\n", "\n")
	}
	return r, nil
}

func executeTemplate(data obj, templateFile, outputFile string) {

	f, err := os.Create(outputFile)
	if err != nil {
		panic(err)
	}
	defer func(f *os.File) {
		_ = f.Close()
	}(f)

	files := []string{
		templateFile,
	}

	ts, err := template.New(filepath.Base(templateFile)).
		Funcs(templateFuncMap).Delims("{%", "%}").ParseFiles(files...)
	if err != nil {
		panic(err)
	}

	err = ts.Execute(f, data)
	if err != nil {
		panic(err)
	}
}
