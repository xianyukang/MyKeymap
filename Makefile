version = 2.0-beta4
ahkVersion = 2.0.7
folder = MyKeymap-$(version)
zip = $(folder).7z

buildServer:
	go.exe build -C ./config-server -ldflags "-s -w -X main.MykeymapVersion=$(version)" -o ../bin/settings.exe ./cmd/settings
	rm -f -r bin/templates
	cp -r config-server/templates bin/templates

buildClient:
	cd config-ui; npm run build
	rm -f config-ui/tsconfig.tsbuildinfo
	cd config-ui/dist/assets; rm -f *.woff *.eot *.ttf

copyFiles:
	rm -f -r $(folder)
	mkdir $(folder)
	mkdir $(folder)/shortcuts

	rm -f -r bin/site
	cp -r config-ui/dist bin/site

	cp -r data $(folder)/
	cp -r bin $(folder)/
	cp -r tools $(folder)/
	cp MyKeymap.exe $(folder)/

build: buildServer buildClient copyFiles
	cd bin; ./settings.exe ChangeVersion $(version)
	rm -f $(zip)
	7z.exe a $(zip) $(folder)
	rm -f -r $(folder)
	@echo ------------------------- build ok -------------------------------

# qshell fput static-x $(zip) $(zip) --overwrite
upload:
	go run build_tools.go checkForAHKUpdate $(ahkVersion)
	python3 lanzou_client.py $(zip) 2> share_link
	go run build_tools.go updateShareLink $(version)
	rm -f share_link
	rm -f readme.md
	mv readme2.md readme.md
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