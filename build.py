#!/usr/bin/env python3


import os
import shutil
import sys
import json

def read_josn(file_path):
    if os.path.isfile(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        return data
    # 文件不存在
    raise ValueError(file_path + ' not found')
        
def write_json(data, file_path):
    with open(file_path, 'r+', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        f.truncate()

arg = ''
if (len(sys.argv) > 1):
    arg = sys.argv[1]

# 构建后端项目
os.chdir('config-back')
os.system('pyinstaller.exe api.py -n mykeymap-settings-server --onefile --icon icon.ico')
os.chdir('..')
shutil.copy('config-back/dist/mykeymap-settings-server.exe', 'bin/')

if (arg == 'server'):
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
os.system('cp -r tools MyKeymap/')


shutil.copy('AutoHotkey.dll', 'MyKeymap/AutoHotkey.dll')
shutil.copy('clip_dll.dll', 'MyKeymap/clip_dll.dll')
shutil.copy('concrt140.dll', 'MyKeymap/concrt140.dll')
shutil.copy('msvcp140.dll', 'MyKeymap/msvcp140.dll')
shutil.copy('msvcp140_1.dll', 'MyKeymap/msvcp140_1.dll')
shutil.copy('msvcp140_2.dll', 'MyKeymap/msvcp140_2.dll')
shutil.copy('msvcp140_atomic_wait.dll', 'MyKeymap/msvcp140_atomic_wait.dll')
shutil.copy('msvcp140_codecvt_ids.dll', 'MyKeymap/msvcp140_codecvt_ids.dll')
shutil.copy('vcamp140.dll', 'MyKeymap/vcamp140.dll')
shutil.copy('vccorlib140.dll', 'MyKeymap/vccorlib140.dll')
shutil.copy('vcomp140.dll', 'MyKeymap/vcomp140.dll')
shutil.copy('vcruntime140.dll', 'MyKeymap/vcruntime140.dll')
shutil.copy('vcruntime140_1.dll', 'MyKeymap/vcruntime140_1.dll')

shutil.copy('MyKeymap.exe', 'MyKeymap/MyKeymap.exe')


if arg == 'upload':
    # 读取 build 数据
    file_path = 'build.json'
    build = read_josn(file_path)

    # 新老文件名
    major = build['version']['major']
    minor = build['version']['minor']
    patch = build['version']['patch']
    old_release_name = '.'.join(map(str, ['MyKeymap-' + str(major), minor, patch, '7z']))
    new_release_name = '.'.join(map(str, ['MyKeymap-' + str(major), minor, patch + 1, '7z']))


    print('打包 7z 文件...')
    os.system(f'rm {old_release_name}')
    os.system(f'7z.exe a {new_release_name} MyKeymap\\')
    
    print('上传文件到对象存储...')
    os.system(f'qshell fput static-x {new_release_name} {new_release_name} --overwrite')

    # 更新 build 数据
    build['version']['patch'] = patch + 1
    write_json(build, file_path)

    print('------------- ok ok ok -------------------------------')
    sys.exit()