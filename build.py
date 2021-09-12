#!/usr/bin/env python3


import os
import shutil
import sys

arg = ''
if (len(sys.argv) > 1):
    arg = sys.argv[1]

if (arg == 'server'):
    # 构建后端项目
    os.chdir('config-back')
    os.system('pyinstaller.exe api.py -n mykeymap-settings-server --onefile --icon icon.ico')
    os.chdir('..')
    shutil.copy('config-back/dist/mykeymap-settings-server.exe', 'bin/')
    sys.exit()


# 清除老版本
shutil.rmtree('MyKeymap', ignore_errors=True)
os.mkdir('MyKeymap/')

# 构建前端项目
os.chdir('config-front')
os.system('pnpm run build')
os.chdir('..')

# 复制 index.html 到 flask 的 templates 文件夹
if not os.path.isdir('bin/templates'):
    os.mkdir('bin/templates')
shutil.copy('bin/site/index.html', 'bin/templates/index.html')
shutil.copy('config-back/templates/script.ahk', 'bin/templates/script.ahk')

# 复制文件
os.system('cp -r data MyKeymap/')
os.system('cp -r bin MyKeymap/')
os.system('cp -r shortcuts MyKeymap/')

os.mkdir('MyKeymap/keymap')
shutil.copy('keymap/caps.ahk', 'MyKeymap/keymap/caps.ahk')
shutil.copy('keymap/functions.ahk', 'MyKeymap/keymap/functions.ahk')

shutil.copy('AutoHotkey.dll', 'MyKeymap/AutoHotkey.dll')
shutil.copy('vcruntime140.dll', 'MyKeymap/vcruntime140.dll')
shutil.copy('clip_dll.dll', 'MyKeymap/clip_dll.dll')
shutil.copy('MyKeymap.exe', 'MyKeymap/MyKeymap.exe')
