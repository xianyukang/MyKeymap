version = 2.0-beta27
ahkVersion = 2.0.12
folder = MyKeymap-$(version)
zip = $(folder).7z

buildServer:
	go.exe build -C ./config-server -ldflags "-s -w -X settings/internal/script.MykeymapVersion=$(version)" -o ../bin/settings.exe ./cmd/settings
	rm -f -r bin/templates
	cp -r config-server/templates bin/templates

buildClient:
	cd config-ui; npm run build
	rm -f config-ui/tsconfig.tsbuildinfo
	cd config-ui/dist/assets; rm -f *.woff *.eot *.ttf

copyFiles: CopyAHK
	rm -f -r $(folder)
	mkdir $(folder)
	mkdir $(folder)/shortcuts

	rm -f -r bin/site
	cp -r config-ui/dist bin/site

	cp -r data $(folder)/
	cp -r bin $(folder)/
	cp -r tools $(folder)/
	cp MyKeymap.exe $(folder)/
	cp 误报病毒时执行这个.bat $(folder)/

# 如果直接用 wsl 的 cp 命令复制, 复制出的文件会有 read-only 属性, 比较奇怪
CopyAHK:
	@echo '@copy /y "C:\\Program Files\\AutoHotkey\\v2\AutoHotkey64.exe" .\\bin\\' > CopyAHK.bat
	cmd.exe /c CopyAHK.bat
	rm CopyAHK.bat

build: buildServer buildClient copyFiles
	cd bin; ./settings.exe ChangeVersion $(version)
	rm -f MyKeymap-*.7z
	7z.exe a $(zip) $(folder)
	rm -f -r $(folder)
	@echo ------------------------- build ok -------------------------------

createRelease:
	curl -L \
		-X POST \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer $$(cat ~/gh_token)" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		https://api.github.com/repos/xianyukang/MyKeymap/releases \
		-d '{"tag_name":"v$(version)","target_commitish":"main","name":"v$(version)","body":"Description of the release"}' 2>/dev/null | jq -r '.id' > release_id
	curl -L \
		-X POST \
		-H "Accept: application/vnd.github+json" \
		-H "Authorization: Bearer $$(cat ~/gh_token)" \
		-H "X-GitHub-Api-Version: 2022-11-28" \
		-H "Content-Type: application/octet-stream" \
		"https://uploads.github.com/repos/xianyukang/MyKeymap/releases/$$(cat release_id)/assets?name=$(zip)" \
		--data-binary "@$(zip)" | jq
	rm release_id


uploadLanZou:
	go run build_tools.go checkForAHKUpdate $(ahkVersion)
	python3 lanzou_client.py $(zip) 2> share_link.json
	go run build_tools.go updateShareLink $(version)
	rm -f share_link.json

upload: uploadLanZou createRelease
	@echo ------------------------- upload ok -------------------------------

# 下面是开发时用到的命令:

server: buildServer
	@cd config-server; ../bin/settings.exe debug

# https://github.com/facebook/create-react-app/issues/10253#issuecomment-747970009
# 坑啊: WSL2 中的 Chokidar 无法监测 Windows 上的文件修改, 导致 hot reload 不起作用
# 需要把项目移到 WSL2 里面, 或者使用 Polling 模式
client:
	@cd config-ui; CHOKIDAR_USEPOLLING=true npm run dev

ahk: buildServer
	@config-server/settings.exe GenerateAHK ./data/config.json ./config-server/templates/mykeymap.tmpl ./bin/MyKeymap.ahk

.PHONY: server client ahk buildServer buildClient copyFiles upload build