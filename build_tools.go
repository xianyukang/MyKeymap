package main

import (
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
