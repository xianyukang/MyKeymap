package main

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
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
	stop := StartTimer("check for AHK update:")
	defer stop()
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
	f, err := os.Open("share_link.json")
	if err != nil {
		panic(err)
	}
	defer f.Close()

	var sl ShareLink
	if err = Decode(f, &sl); err != nil {
		panic(err)
	}

	var format string
	replacer := func(line string) string {
		if strings.Index(line, "提取码") != -1 {
			return fmt.Sprintf(format, args[0], sl.Url, sl.Password)
		}
		return line
	}

	format = "- [MyKeymap %s](%s) ( 提取码 %s )"
	if err = ReplaceInFile("./readme.md", replacer); err != nil {
		panic(err)
	}

	format = "- 下载地址: [MyKeymap %s](%s) ( 提取码 %s )"
	_ = ReplaceInFile("/mnt/d/project/my_site/docs/MyKeymap.md", replacer)
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

func CreateTempFile() (*os.File, func(), error) {
	f, err := os.CreateTemp(".", "tmp.*.txt")

	cleanup := func() {
		_ = os.Remove(f.Name())
	}

	return f, cleanup, err
}

type File struct {
	closed bool
	*os.File
}

func (m *File) Close(err *error) {
	// 确保只调用一次 Close
	if m.closed {
		return
	}
	closeErr := m.File.Close()
	m.closed = true

	// 如果之前没有发生错误, 并且 Close() 时发生了错误, 那么修改返回的错误值
	if *err == nil {
		*err = closeErr
	}
}

func ReplaceInFile(filename string, handler func(string) string) (err error) {
	// 打开目标文件
	f, err := os.Open(filename)
	if err != nil {
		return err
	}
	mf := File{File: f}
	defer mf.Close(&err)

	// 创建临时文件, 用于写入
	f, cleanup, err := CreateTempFile()
	if err != nil {
		return err
	}
	defer cleanup()
	wf := File{File: f}
	defer wf.Close(&err)

	// 按行读取时, 默认 buffer 大小为 64K, 如果某行会超出 64K, 需要设置更大的 buffer
	// 参考此处: https://stackoverflow.com/a/16615559
	scanner := bufio.NewScanner(mf)
	writer := bufio.NewWriter(wf)
	for scanner.Scan() {
		line := scanner.Text()
		if _, err = writer.WriteString(handler(line) + "\n"); err != nil {
			return err
		}
	}

	// Scan 方法会在遇到错误时返回 false, 所以别忘了检查错误
	if err = scanner.Err(); err != nil {
		return err
	}

	if err = writer.Flush(); err != nil {
		return err
	}

	// 提前关闭两个文件 ( 因为之后要 Rename )
	mf.Close(&err)
	if err != nil {
		return err
	}
	wf.Close(&err)
	if err != nil {
		return err
	}
	return os.Rename(wf.Name(), mf.Name())
}

func StartTimer(name string) func() {
	t := time.Now()
	log.Println(name, "started")
	return func() {
		d := time.Now().Sub(t)
		log.Println(name, "took", d)
	}
}

type Valid interface {
	OK() error
}

type ShareLink struct {
	Url      string `json:"url"`
	Password string `json:"password"`
}

// OK 实现了 Valid 接口, 这样在 Decode 时顺便校验数据是否合法
func (s ShareLink) OK() error {
	if s.Url == "" {
		return errors.New("url required")
	}
	if s.Password == "" {
		return errors.New("password required")
	}
	return nil
}

func Decode[T any](r io.Reader, v *T) error {
	err := json.NewDecoder(r).Decode(v)
	if err != nil {
		return err
	}

	obj, ok := any(v).(Valid) // 注意 *T 是一个具体类型 ( 比如 *int ) 所以不能用 type assertion
	if !ok {
		return nil // 类型没有 OK 方法, 所以直接返回, 不执行 OK 方法
	}
	return obj.OK()
}
