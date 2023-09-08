package main

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"
)

func main() {
	m := map[string]func(args []string){
		"checkForAHKUpdate": checkForAHKUpdate,
		"updateShareLink":   updateShareLink,
	}
	if f, ok := m[os.Args[1]]; ok {
		f(os.Args[2:])
	}
}

func checkForAHKUpdate(args []string) {
	currentVersion := args[0]
	version, err := getURL("https://www.autohotkey.com/download/2.0/version.txt")
	if err != nil {
		panic(err)
	}
	if version != currentVersion {
		fmt.Println("error: outdated ahk version")
		os.Exit(1)
	}
}

func updateShareLink(args []string) {
	data, err := os.ReadFile("./share_link")
	if err != nil {
		panic(err)
	}

	items := strings.Fields(string(data))
	version := args[0]
	url := items[0]
	pwd := items[1]
	fmt.Println("url:", url, "password:", pwd)

	f, err := os.Open("./readme.md")
	if err != nil {
		panic(err)
	}
	defer f.Close()

	wf, err := os.Create("./readme2.md")
	if err != nil {
		panic(err)
	}
	defer wf.Close()

	// 按行读取时, 默认 buffer 大小为 64K, 如果某行会超出 64K, 需要设置更大的 buffer
	// 参考此处: https://stackoverflow.com/a/16615559
	scanner := bufio.NewScanner(f)
	writer := bufio.NewWriter(wf)
	defer writer.Flush()
	for scanner.Scan() {
		line := scanner.Text()
		if strings.Index(line, "提取码") != -1 {
			line = fmt.Sprintf("- [MyKeymap %s](%s) ( 提取码 %s )\n", version, url, pwd)
			_, _ = writer.WriteString(line)
		} else {
			_, _ = writer.WriteString(line)
			_, _ = writer.WriteString("\n")
		}
	}

	// Scan 方法会在遇到错误时返回 false, 所以别忘了检查错误
	if err := scanner.Err(); err != nil {
		panic(err)
	}
}

func execCmd(exe string, args ...string) {
	var c = exec.Command(exe, args...)
	c.Stdout = os.Stdout
	c.Stderr = os.Stderr
	fmt.Printf("\n%s %s\n", exe, strings.Join(args, " "))
	err := c.Start()
	if err != nil {
		panic(err)
	}
	err = c.Wait()
	if err != nil {
		panic(err)
	}
}

func getURL(url string) (string, error) {
	client := &http.Client{
		Timeout: 5 * time.Second,
	}

	req, err := http.NewRequestWithContext(context.Background(), http.MethodGet, url, nil)
	if err != nil {
		return "", err
	}

	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}

	defer resp.Body.Close()
	body, err := io.ReadAll(resp.Body)
	return string(body), err
}
