package command

import (
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"settings/internal/script"
	"strings"
	"text/template"
)

var Map = map[string]func(args ...string){
	"AlignText":       AlignText,
	"GenerateAHK":     GenerateAHK,
	"ChangeVersion":   ChangeVersion,
	"GenerateScripts": GenerateScripts,
}

var logger = log.New(os.Stderr, "", 0)

func GenerateAHK(args ...string) {
	if len(os.Args) < 5 {
		logger.Fatal("GenerateAHK requires 3 arguments, for example: GenerateAHK ./config.json ./templates/script.ahk ./output.ahk")
	}
	configFile := os.Args[2]
	templateFile := os.Args[3]
	outputFile := os.Args[4]

	config, err := script.ParseConfig(configFile)
	if err != nil {
		logger.Fatal(err)
	}

	if err := script.SaveAHK(config, templateFile, outputFile); err != nil {
		logger.Fatal(err)
	}
}

func ChangeVersion(args ...string) {
	config, err := script.ParseConfig("../data/config.json")
	if err != nil {
		panic(err)
	}
	config.Options.MykeymapVersion = args[0]
	script.SaveConfigFile(config)
	script.GenerateScripts(config)
}

func GenerateScripts(args ...string) {
	config, err := script.ParseConfig("../data/config.json")
	if err != nil {
		panic(err)
	}
	script.GenerateScripts(config)
}

func AlignText(args ...string) {
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

func executeTemplate(data map[string]interface{}, templateFile, outputFile string) {

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
		Funcs(script.TemplateFuncMap).Delims("{%", "%}").ParseFiles(files...)
	if err != nil {
		panic(err)
	}

	err = ts.Execute(f, data)
	if err != nil {
		panic(err)
	}
}
