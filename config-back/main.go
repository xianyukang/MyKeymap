package main

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-contrib/static"
	"github.com/gin-gonic/gin"
	"github.com/goccy/go-json"
	"io/ioutil"
	"net/http"
	"os"
	"os/exec"
	"text/template"
)

func main() {
	gin.SetMode(gin.ReleaseMode)
	router := gin.Default()
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
