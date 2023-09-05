package main

import (
	"bytes"
	"fmt"
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
	"text/template"
	"time"
)

var MykeymapVersion string

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
	if debug {
		hasError = nil
	}

	execCmd("./MyKeymap.exe", "WithoutAdmin", "./bin/MiscTools.ahk", "GenerateShortcuts")
	server(hasError, rainDone, debug)
}

func server(hasError chan<- struct{}, rainDone <-chan struct{}, debug bool) {
	if !debug {
		gin.SetMode(gin.ReleaseMode)
		gin.DefaultWriter = io.Discard
	}

	router := gin.Default()
	router.Use(PanicHandler(hasError, rainDone))
	if debug {
		router.Use(cors.Default())
	}
	router.NoRoute(static.Serve("/", static.LocalFile("./site", false)), indexHandler)

	router.GET("/", indexHandler)
	router.GET("/config", GetConfigHandler)
	router.PUT("/config", SaveConfigHandler(debug))
	router.POST("/server/command/:id", ServerCommandHandler)
	router.GET("/shortcuts", GetShortcutsHandler)

	// 先尝试 12333 端口, 失败了则用随机端口. 因为 12333 端口可能已被占用, 或者被禁:
	// An attempt was made to access a socket in a way forbidden by its access permissions.
	ln, err := net.Listen("tcp", "localhost:12333")
	if err != nil {
		ln, err = net.Listen("tcp", "localhost:0")
		if err != nil {
			close(hasError)
			<-rainDone
			fmt.Println("Error:", err.Error())
			_, _ = fmt.Scanln()
			os.Exit(1)
		}
	}

	if !debug {
		go openBrowser(ln.Addr())
	}

	err = router.RunListener(ln)
	if err != nil {
		close(hasError)
		<-rainDone
		log.Fatal(err)
	}
}

func openBrowser(addr net.Addr) {
	time.Sleep(600 * time.Millisecond)
	//goland:noinspection HttpUrlsUsage
	_ = exec.Command("cmd", "/c", "start", "http://"+addr.String()).Start()
}

func indexHandler(c *gin.Context) {
	data, err := os.ReadFile("./site/index.html")
	if err != nil {
		panic(err)
	}
	// 设置 Cache-Control: no-store 禁用缓存
	c.Header("Cache-Control", "no-store")
	c.Data(http.StatusOK, "text/html; charset=utf-8", data)
}

func GetConfigHandler(c *gin.Context) {
	config, err := script.ParseConfig("../data/config.json")
	if err != nil {
		panic(err)
	}
	config.Options.MykeymapVersion = MykeymapVersion
	c.JSON(http.StatusOK, config)
}

func GetShortcutsHandler(c *gin.Context) {
	type shortcut struct {
		Path string `json:"path"`
	}
	exe, err := os.Executable()
	if err != nil {
		panic(err)
	}
	root := filepath.Dir(filepath.Dir(exe))
	pattern := filepath.Join(root, "shortcuts", "*.lnk")

	files, err := filepath.Glob(pattern)
	if err != nil {
		panic(err)
	}
	var data []shortcut
	for _, f := range files {
		data = append(data, shortcut{
			Path: f[len(root)+1:],
		})
	}
	c.JSON(http.StatusOK, data)
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
		"3": {
			exe:  "./MyKeymap.exe",
			args: []string{"WithoutAdmin", "./bin/MiscTools.ahk", "RunAtStartup", "On"},
		},
		"4": {
			exe:  "./MyKeymap.exe",
			args: []string{"WithoutAdmin", "./bin/MiscTools.ahk", "RunAtStartup", "Off"},
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

func SaveConfigHandler(debug bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		var config script.Config
		if err := c.ShouldBindJSON(&config); err != nil {
			panic(err)
		}

		// 生成帮助文件
		// helpPageHtml := config["helpPageHtml"].(string)
		// delete(config, "helpPageHtml")
		// saveHelpPageHtml(helpPageHtml)

		saveConfigFile(config) // 保存配置文件

		if debug {
			script.GenerateScripts(&config)                 // 生成脚本文件
			execCmd("./MyKeymap.exe", "./bin/MyKeymap.ahk") // 重启程序且跳过 ahk 脚本生成
		} else {
			execCmd("./MyKeymap.exe") // 重启程序, 此时 launcher 会重新生成脚本
		}

		c.JSON(http.StatusOK, gin.H{"message": "ok"})
	}
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
