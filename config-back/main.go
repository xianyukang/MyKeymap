package main

import (
	"fmt"
	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/goccy/go-json"
	"io"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"text/template"
	"time"
)

func main() {

	hasError := make(chan struct{})
	errorLog := new(strings.Builder)
	debug := len(os.Args) == 2 && os.Args[1] == "debug"

	if debug {
		server(errorLog, hasError, debug)
	}

	go server(errorLog, hasError, debug)
	matrix(hasError)

	// 要等 gin 协程把错误日志打印完, 才能在这边读取错误日志
	// 之前试了半天没发现是什么问题,  这就是并发程序的复杂性,  这里等 300ms 属于偷懒的办法
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
	router.Use(static.Serve("/", static.LocalFile("./site", false)))

	router.GET("/config", GetConfigHandler)
	router.PUT("/config", SaveConfigHandler)
	router.POST("/execute", ExecuteHandler)

	err := router.Run(":12333")
	if err != nil {
		panic(err)
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
		err := c.Start()
		if err != nil {
			panic(err)
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
	generateScript(config)

	c.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func saveConfigFile(config map[string]interface{}) {
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
