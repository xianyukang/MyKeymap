go:
	@go.exe build -C ./config-server -ldflags "-s -w" ./cmd/settings

ahk: go
	@config-server/settings.exe GenerateAHK ./data/config.json ./config-server/templates/mykeymap.tmpl ./bin/MyKeymap.ahk

server: go
	@cd config-server; ./settings.exe debug

# https://github.com/facebook/create-react-app/issues/10253#issuecomment-747970009
# 坑啊: WSL2 中的 Chokidar 无法监测 Windows 上的文件修改, 导致 hot reload 不起作用
# 需要把项目移到 WSL2 里面, 或者使用 Polling 模式
client:
	@cd config-ui; CHOKIDAR_USEPOLLING=true npm run dev

.PHONY: server client ahk go