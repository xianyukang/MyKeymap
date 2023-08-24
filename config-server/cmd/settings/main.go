package main

import (
	"bytes"
	"fmt"
	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/goccy/go-json"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"settings/internal/command"
	"settings/internal/matrix"
	"strings"
	"text/template"
	"time"
)

func main() {

	if len(os.Args) >= 2 {
		if handler, ok := command.Map[os.Args[1]]; ok {
			handler()
			return
		}
	}

	hasError := make(chan struct{})
	errorLog := new(strings.Builder)
	debug := len(os.Args) == 2 && os.Args[1] == "debug"

	if debug {
		server(errorLog, hasError, debug)
	}

	go server(errorLog, hasError, debug)
	matrix.DigitalRain(hasError)

	// 要等 gin 协程把错误日志打印完, 才能在这边读取错误日志
	// 之前试了半天没发现是什么问题,  这里等 300ms 属于偷懒的办法
	time.Sleep(300 * time.Millisecond)
	fmt.Println(errorLog.String())

	fmt.Println("发生了上述错误, 可以截图发给作者")
	_, _ = fmt.Scanln()
}

func server(errorLog *strings.Builder, hasError chan<- struct{}, debug bool) {
	if !debug {
		gin.SetMode(gin.ReleaseMode)
		gin.DefaultWriter = io.Discard
		gin.DefaultErrorWriter = errorLog
	}

	router := gin.Default()
	router.Use(PanicHandler(hasError))
	router.Use(cors.Default())
	router.Use(IndexHandler())
	router.Use(static.Serve("/", static.LocalFile("./site", false)))

	router.GET("/config", GetConfigHandler)
	router.PUT("/config", SaveConfigHandler)
	router.POST("/execute", ExecuteHandler)

	// 一个常见错误是端口已被占用,  除了检查字符串,  有没有什么预定义的 sentinel error 可以用?
	ln, err := net.Listen("tcp", "127.0.0.1:12333")
	if err != nil && strings.Index(err.Error(), "Only one usage of each socket address ") != -1 {
		errorLog.WriteString("Error: 已经有一个程序占用了 12333 端口\n")
		close(hasError)
		return
	}

	if !debug {
		go openBrowser()
	}

	err = router.RunListener(ln)
	if err != nil {
		errorLog.WriteString(err.Error())
		close(hasError)
	}
}

func openBrowser() {
	time.Sleep(600 * time.Millisecond)
	_ = exec.Command("cmd", "/c", "start", "http://127.0.0.1:12333").Start()
}

func IndexHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.URL.Path == "/" {
			data, err := ioutil.ReadFile("./site/index.html")
			if err != nil {
				panic(err)
			}
			c.Header("Cache-Control", "no-store")
			c.Data(http.StatusOK, "text/html; charset=utf-8", data)
			c.Abort()
		}
	}
}

func GetConfigHandler(c *gin.Context) {
	data, err := ioutil.ReadFile("../data/config.json")
	if err != nil {
		panic(err)
	}
	c.Data(http.StatusOK, gin.MIMEJSON, data)
}

func PanicHandler(hasError chan<- struct{}) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				close(hasError)
				panic(err)
			}
		}()

		c.Next()
	}
}

func ExecuteHandler(c *gin.Context) {
	var command map[string]interface{}
	if err := c.ShouldBindJSON(&command); err != nil {
		panic(err)
	}
	if command["type"].(string) == "run-program" {
		val := command["value"].([]interface{})
		exe := val[0].(string)
		arg := val[1].(string)

		// 切换到 parent 文件夹, 执行完 command 后再回来
		// 程序工作目录算全局共享状态, 所以会影响到其他 goroutine
		wd, err := os.Getwd()
		if err == nil {
			base := filepath.Base(wd)
			fmt.Println(wd, base, exe, arg)
			err := os.Chdir("../")
			if err == nil {
				defer func() {
					_ = os.Chdir(base)
				}()
			}
		}

		var c = exec.Command(exe, arg)
		if len(val) == 3 {
			arg2 := val[2].(string)
			c = exec.Command(exe, arg, arg2)
		}
		// 忽略执行错误
		err = c.Start()
		if err != nil {

		}
	}
	c.JSON(http.StatusOK, command)
}

func SaveConfigHandler(c *gin.Context) {
	var config map[string]interface{}
	if err := c.ShouldBindJSON(&config); err != nil {
		panic(err)
	}

	// 生成帮助文件
	helpPageHtml := config["helpPageHtml"].(string)
	delete(config, "helpPageHtml")
	saveHelpPageHtml(helpPageHtml)

	// 保存配置文件
	saveConfigFile(config)

	// 生成脚本文件
	// script.GenerateScript(config)

	c.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func saveConfigFile(config map[string]interface{}) {
	// 先写到缓冲区,  如果直接写文件的话, 当编码过程遇到错误时, 会导致文件损坏
	buf := new(bytes.Buffer)
	encoder := json.NewEncoder(buf)
	encoder.SetIndent("", "    ")
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(config); err != nil {
		panic(err)
	}

	if err := os.WriteFile("../data/config.json", buf.Bytes(), 0644); err != nil {
		panic(err)
	}
}

func saveHelpPageHtml(html string) {

	f, err := os.Create("../bin/site/help.html")
	if err != nil {
		panic(err)
	}
	defer func(f *os.File) {
		_ = f.Close()
	}(f)

	files := []string{
		"./templates/help.html",
	}

	ts, err := template.ParseFiles(files...)
	if err != nil {
		panic(err)
	}
	err = ts.Execute(f, map[string]string{"helpPageHtml": html})
	if err != nil {
		panic(err)
	}
}
