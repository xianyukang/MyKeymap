ahk: go
	@config-server/settings.exe GenerateAHK ./data/config2.json ./config-server/templates/mykeymap.tmpl ./bin/MyKeymap.ahk
go:
	@go.exe build -C ./config-server -ldflags "-s -w" ./cmd/settings

.PHONY: server client ahk go