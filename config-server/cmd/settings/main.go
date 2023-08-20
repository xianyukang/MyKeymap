package main

import (
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
	router.Use(ErrorHandler(hasError))
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

	// File Server 返回文件时设置了 Last-Modified 响应头,  所以浏览器会使用缓存
	// 从旧版本升级时,  比如从 MyKeymap 1.1 升级到了 1.2,  打开浏览器会发现版本依旧是 1.1
	// 解决办法是不让 File Server 返回 index.html,  去掉 Last-Modified 响应头以关掉缓存机制

	// 假设有这样一串中间件 A->B->C:
	// (1) 首先无论加不加 c.Next() 中间件都会顺序执行
	// (2) 其中的 A 想在 B、C 处理完成后,  做一些后续工作,  这时候才需要用到 c.Next()
	// (3) 如果 A 像中断流程, 那么调用一下 c.Abort()

	return func(c *gin.Context) {
		if c.Request.URL.Path == "/" {
			data, err := ioutil.ReadFile("./site/index.html")
			if err != nil {
				panic(err)
			}
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

func ErrorHandler(hasError chan<- struct{}) gin.HandlerFunc {
	// 参考这几篇教程
	// https://juejin.cn/post/7064770224515448840
	// https://segmentfault.com/a/1190000020358030
	// https://stackoverflow.com/questions/69948784/how-to-handle-errors-in-gin-middleware
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
		exe := "../" + val[0].(string)
		arg := "../" + val[1].(string)
		var c = exec.Command(exe, arg)
		if len(val) == 3 {
			arg2 := val[2].(string)
			c = exec.Command(exe, arg, arg2)
		}
		// 忽略错误
		err := c.Start()
		if err != nil {
			// panic(err)
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
	// os.Create 会清空文件, 这一步应该放在最后, 避免遇错返回, 但文件却被清空了
	f, err := os.Create("../data/config.json")
	if err != nil {
		panic(err)
	}
	defer func(f *os.File) {
		_ = f.Close()
	}(f)

	encoder := json.NewEncoder(f)
	encoder.SetIndent("", "    ")
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(config); err != nil {
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
