package main

import (
	"bytes"
	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/goccy/go-json"
	"io"
	"log"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"settings/internal/command"
	"settings/internal/matrix"
	"settings/internal/script"
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
	rainDone := make(chan struct{})
	debug := len(os.Args) == 2 && os.Args[1] == "debug"

	if !debug {
		go matrix.DigitalRain(hasError, rainDone)
	}

	server(hasError, rainDone, debug)
}

func server(hasError chan<- struct{}, rainDone <-chan struct{}, debug bool) {
	if !debug {
		gin.SetMode(gin.ReleaseMode)
		gin.DefaultWriter = io.Discard
	}

	router := gin.Default()
	router.Use(PanicHandler(hasError, rainDone))
	router.Use(cors.Default())
	router.Use(IndexHandler())
	router.Use(static.Serve("/", static.LocalFile("./site", false)))

	router.GET("/config", GetConfigHandler)
	router.PUT("/config", SaveConfigHandler)
	router.POST("/server/command/:id", ServerCommandHandler)

	// 一个常见错误是端口已被占用
	ln, err := net.Listen("tcp", "127.0.0.1:12333")
	if err != nil && strings.Index(err.Error(), "Only one usage of each socket address ") != -1 {
		close(hasError)
		<-rainDone
		log.Fatal("Error: 已经有一个程序占用了 12333 端口\n")
	}

	if !debug {
		go openBrowser()
	}

	err = router.RunListener(ln)
	if err != nil {
		close(hasError)
		<-rainDone
		log.Fatal(err)
	}
}

func openBrowser() {
	time.Sleep(600 * time.Millisecond)
	_ = exec.Command("cmd", "/c", "start", "http://127.0.0.1:12333").Start()
}

func IndexHandler() gin.HandlerFunc {
	return func(c *gin.Context) {
		if c.Request.URL.Path == "/" {
			data, err := os.ReadFile("./site/index.html")
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
	data, err := os.ReadFile("../data/config.json")
	if err != nil {
		panic(err)
	}
	c.Data(http.StatusOK, gin.MIMEJSON, data)
}

func PanicHandler(hasError chan<- struct{}, rainDone <-chan struct{}) gin.HandlerFunc {
	return func(c *gin.Context) {
		defer func() {
			if err := recover(); err != nil {
				// 不允许重复 close channel
				if hasError != nil {
					close(hasError)
					<-rainDone
					hasError = nil
				}
				panic(err)
			}
		}()

		c.Next()
	}
}

func ServerCommandHandler(c *gin.Context) {
	m := map[string]struct {
		exe  string
		args []string
	}{
		"2": {
			exe:  "./MyKeymap.exe",
			args: []string{"bin/WindowSpy.ahk"},
		},
	}
	if c, ok := m[c.Param("id")]; ok {
		execCmd(c.exe, c.args...)
	}

	c.JSON(http.StatusOK, gin.H{})
}

func execCmd(exe string, args ...string) {
	// 切换到 parent 文件夹, 执行完 command 后再回来
	// 程序工作目录算全局共享状态, 所以会影响到其他 goroutine
	wd, err := os.Getwd()
	if err == nil {
		base := filepath.Base(wd)
		err := os.Chdir("../")
		if err == nil {
			defer func() {
				_ = os.Chdir(base)
			}()
		}
	}

	var c = exec.Command(exe, args...)
	err = c.Start()
	if err != nil {
	}
}

func SaveConfigHandler(c *gin.Context) {
	var config script.Config
	if err := c.ShouldBindJSON(&config); err != nil {
		panic(err)
	}

	// 生成帮助文件
	// helpPageHtml := config["helpPageHtml"].(string)
	// delete(config, "helpPageHtml")
	// saveHelpPageHtml(helpPageHtml)

	saveConfigFile(config)          // 保存配置文件
	script.GenerateScripts(&config) // 生成脚本文件
	execCmd("./MyKeymap.exe")       // 重启程序

	c.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func saveConfigFile(config script.Config) {
	// 先写到缓冲区,  如果直接写文件的话, 当编码过程遇到错误时, 会导致文件损坏
	buf := new(bytes.Buffer)
	encoder := json.NewEncoder(buf)
	encoder.SetIndent("", "  ")
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
