package main

import (
	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/goccy/go-json"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"text/template"
)

func main() {
	router := gin.Default()
	router.Use(cors.Default())

	router.GET("/config", GetConfigHandler)
	router.PUT("/config", SaveConfigHandler)

	err := router.Run(":12333")
	if err != nil {
		log.Fatal(err)
	}
}

func GetConfigHandler(c *gin.Context) {
	data, err := ioutil.ReadFile("../data/config.json")
	if err != nil {
		log.Fatal(err)
	}
	c.Data(http.StatusOK, gin.MIMEJSON, data)
}

func SaveConfigHandler(c *gin.Context) {
	var config map[string]interface{}
	if err := c.ShouldBindJSON(&config); err != nil {
		log.Fatal(err)
	}

	// 生成帮助文件
	helpPageHtml := config["helpPageHtml"].(string)
	delete(config, "helpPageHtml")
	saveHelpPageHtml(helpPageHtml)

	// 保存配置文件
	saveConfigFile(config)

	// 生成脚本文件

	c.JSON(http.StatusOK, gin.H{"message": "ok"})
}

func saveConfigFile(config map[string]interface{}) {
	f, err := os.Create("../data/config.json")
	if err != nil {
		log.Fatal(err)
	}
	defer func(f *os.File) {
		_ = f.Close()
	}(f)

	encoder := json.NewEncoder(f)
	encoder.SetIndent("", "    ")
	encoder.SetEscapeHTML(false)
	if err := encoder.Encode(config); err != nil {
		log.Fatal(err)
	}
}

func saveHelpPageHtml(html string) {

	f, err := os.Create("../bin/site/help.html")
	if err != nil {
		log.Fatal(err)
	}
	defer func(f *os.File) {
		_ = f.Close()
	}(f)

	files := []string{
		"./templates/help.html",
	}

	ts, err := template.ParseFiles(files...)
	if err != nil {
		log.Fatal(err)
	}
	err = ts.Execute(f, map[string]string{"helpPageHtml": html})
	if err != nil {
		log.Fatal(err)
	}
}
