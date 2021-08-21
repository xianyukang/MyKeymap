#!/usr/bin/env python3


import os
import shutil

# 清除老版本
shutil.rmtree('MyKeymap', ignore_errors=True)
os.mkdir('MyKeymap/')
os.mkdir('MyKeymap/bin/')

# 构建后端项目
os.chdir('config-back')
os.system('pyinstaller.exe api.py --onefile --icon icon.ico')
os.chdir('..')
shutil.move('config-back/dist/api.exe', 'MyKeymap/bin/')

# 构建前端项目
os.chdir('config-front')
os.system('pnpm run build')
os.chdir('..')

# 复制 index.html 到 flask 的 templates 文件夹
os.mkdir('MyKeymap/bin/templates/')
shutil.copy('MyKeymap/bin/site/index.html', 'MyKeymap/bin/templates/')

# 复制文件
os.system('cp -r data MyKeymap/')
os.system('cp -r shortcuts MyKeymap/')

os.mkdir('MyKeymap/keymap')
shutil.copy('keymap/caps.ahk', 'MyKeymap/keymap/caps.ahk')
shutil.copy('config-back/templates/script.ahk', 'MyKeymap/bin/templates/script.ahk')
shutil.copy('keymap/functions.ahk', 'MyKeymap/keymap/functions.ahk')

shutil.copy('AutoHotkey.dll', 'MyKeymap/AutoHotkey.dll')
shutil.copy('vcruntime140.dll', 'MyKeymap/vcruntime140.dll')
shutil.copy('clip_dll.dll', 'MyKeymap/clip_dll.dll')
shutil.copy('MyKeymap.exe', 'MyKeymap/MyKeymap.exe')
shutil.copy('bin/logo.ico', 'MyKeymap/bin/logo.ico')
