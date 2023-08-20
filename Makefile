go:
	@go.exe build -C ./config-server -ldflags "-s -w" ./cmd/settings

ahk: go
	@config-server/settings.exe GenerateAHK ./data/config.json ./config-server/templates/mykeymap.tmpl ./bin/MyKeymap.ahk

server: go
	@cd config-server; ./settings.exe debug

client:
	@cd config-ui; npm run dev

.PHONY: server client ahk go