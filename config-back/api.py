#!/usr/bin/env python3

import os
import json
from flask import jsonify
from flask import request
from flask import Flask
from flask import render_template
from ahk_script import AhkScript
from flask_cors import CORS
import subprocess
import sys

# 如何禁用 flask 的启动信息、各种日志...
# https://stackoverflow.com/a/57086684/15989650

app = Flask(__name__, static_url_path='', static_folder='site',)
CORS(app)
app.config['JSON_SORT_KEYS'] = False
script = AhkScript()

import logging
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)


@app.route('/', methods=['GET'])
def index_page():
    return render_template('index.html')


@app.route('/config', methods=['GET'])
def get_config():
    with open('../data/config.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
        return jsonify(data)

@app.route('/config', methods=['PUT'])
def save_config():
    data = request.get_json()
    with open('../data/config.json', 'r+', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        f.truncate()
    script.makeCapslock(data)
    return 'save config ok!'

@app.route('/execute', methods=['POST'])
def execute():
    command = request.get_json()
    # print(command)
    if command['type'] == 'run-program':
        # print(os.getcwd())
        val = list(map(lambda x: '../' + x, command['value']))
        # print(val)
        subprocess.Popen(val)
    return command

def serveApi():

    # os.system('chcp 65001')
    os.system('cls')
    print()
    print('   ------------------------------------------------------------------')
    print('   1. 打开浏览器访问 http://localhost:12333 修改 MyKeyamp 的配置')
    print('   2. 保存配置后需要按 alt+\' 重启 MyKeymap (这里的\'是单引号键) ')
    print('   3. 修改完 MyKeymap 的配置后即可关闭本窗口')
    print('   ------------------------------------------------------------------')
    script_compiled = getattr(sys, 'frozen', False)
    if script_compiled:
        app.run(port=12333, debug=False)
    else:
        # os.environ['WERKZEUG_RUN_MAIN'] = 'true'    # 关掉 flask 启动消息
        app.run(port=12333, debug=True)

if __name__ == '__main__':
    arg = '--server'
    if len(sys.argv) >= 2:
        arg = sys.argv[1]
    if (arg == '--server'):
        serveApi()
    elif (arg == '--rain'):
        # Windows 中需要 pip.exe install windows-curses
        from unimatrix import startRain
        startRain()