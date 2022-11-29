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

def get_version_info(file = "build.json"):
    build = read_josn(file)
    major = build['version']['major']
    minor = build['version']['minor']
    patch = build['version']['patch']
    return major, minor, patch

arg = ''
if (len(sys.argv) > 1):
    arg = sys.argv[1]

# 增加版本号
# os.system('go.exe run add-version.go')

# 构建后端项目
os.chdir('config-back')
os.system('go.exe build -ldflags "-s -w"')
os.chdir('..')
if os.path.isfile("bin/settings.exe"):
    os.remove("bin/settings.exe")
shutil.move("config-back/settings.exe", "bin/")
if (arg == 'go'):
    sys.exit()

# 构建后端项目
# shutil.rmtree('bin/mykeymap-settings-server', ignore_errors=True)
# os.chdir('config-back')
# os.system('pyinstaller.exe api.py -n mykeymap-settings-server -y --clean --icon icon.ico')
# os.chdir('..')
# os.system('cp -r config-back/dist/mykeymap-settings-server bin/')

# if (arg == 'server'):
#     sys.exit()


# 清除老版本
major, minor, patch = get_version_info()
new_folder_name = "MyKeymap-" + ".".join([str(major), str(minor), str(patch+1)])
shutil.rmtree(new_folder_name, ignore_errors=True)
os.mkdir('MyKeymap/')

# 构建前端项目

os.chdir('tailwind')
os.system('npm run build')
os.chdir('..')

os.chdir('config-front')
os.system('pnpm run build')
os.chdir('..')

# 构建 tailwind css
os.chdir('tailwind')
os.system('npm run build-help-page-css')
os.system('npm run build-html-tools-css')
os.chdir('..')

# 删除无用文件、减小打包体积
os.system('rm bin/site/fonts/*.eot')
os.system('rm bin/site/fonts/*.woff')
os.system('rm bin/site/fonts/*.ttf')
os.system('rm bin/site/js/*.map')

# 复制 index.html 到 flask 的 templates 文件夹
if not os.path.isdir('bin/templates'):
    os.mkdir('bin/templates')
shutil.copy('bin/site/index.html', 'bin/templates/index.html')
# shutil.copy('config-back/templates/script.ahk', 'bin/templates/script.ahk')
shutil.copy('config-back/templates/script2.ahk', 'bin/templates/script2.ahk')
shutil.copy('config-back/templates/CustomShellMenu.ahk', 'bin/templates/CustomShellMenu.ahk')
shutil.copy('config-back/templates/help.html', 'bin/templates/help.html')

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
shutil.copy('vcruntime140.dll', 'MyKeymap/bin/vcruntime140.dll')
shutil.copy('vcruntime140_1.dll', 'MyKeymap/bin/vcruntime140_1.dll')

shutil.copy('MyKeymap.exe', 'MyKeymap/MyKeymap.exe')
shutil.copy('SoundControl.exe', 'MyKeymap/SoundControl.exe')
shutil.copy('font.ttf', 'MyKeymap/font.ttf')
shutil.copy('设置程序.lnk', 'MyKeymap/设置程序.lnk')


os.rename("MyKeymap", new_folder_name)

if arg == 'upload':
    # 读取 build 数据
    file_path = 'build.json'
    build = read_josn(file_path)

    # 新老文件名
    old_release_name = '.'.join(map(str, ['MyKeymap-' + str(major), minor, patch, '7z']))
    new_release_name = '.'.join(map(str, ['MyKeymap-' + str(major), minor, patch + 1, '7z']))


    print('打包 7z 文件...')
    os.system(f'rm {old_release_name}')
    os.system(f'7z.exe a {new_release_name} {new_folder_name}\\')
    
    print('上传文件到对象存储...')
    os.system(f'qshell fput static-x {new_release_name} {new_release_name} --overwrite')

    # 更新 build 数据
    build['version']['patch'] = patch + 1
    write_json(build, file_path)

    print('------------- ok ok ok -------------------------------')
    sys.exit()