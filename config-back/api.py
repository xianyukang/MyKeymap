#!/usr/bin/env python3

import os
import json
from flask import jsonify
from flask import request
from flask import Flask
from flask import render_template
from ahk_script import AhkScript
from flask_cors import CORS
# from multiprocessing import Process
import traceback
import subprocess
import sys
from template_engine import template_engine

# 如何禁用 flask 的启动信息、各种日志...
# https://stackoverflow.com/a/57086684/15989650

base_dir = os.getcwd()
static_dir = os.path.join(base_dir, 'site')
template_dir = os.path.join(base_dir, 'templates')
print(base_dir)

app = Flask(__name__, static_url_path='', static_folder=static_dir, template_folder=template_dir)
CORS(app)
app.config['JSON_SORT_KEYS'] = False
script = AhkScript()

import logging
log = logging.getLogger('werkzeug')
log.setLevel(logging.ERROR)

# def browser_open(url):
#     import webbrowser
#     webbrowser.open_new(url)

# def get_random_port():
#     import socket
#     sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
#     sock.bind(('127.0.0.1', 0))
#     port = sock.getsockname()[1]
#     sock.close()
#     return port

def saveHelpPageHtml(html):
    template = template_engine.get_template('help.html')
    with open("../bin/site/help.html", "w+", encoding="utf-8") as f:
        print(template.render(helpPageHtml=html), file=f)
    return

def print_banner(url):
    print()
    print('   ------------------------------------------------------------------')
    print(f'   1. 打开浏览器访问 {url} 修改 MyKeyamp 的配置')
    print('   2. 保存配置后需要按 alt+\' 重启 MyKeymap (这里的\'是单引号键) ')
    print('   3. 修改完 MyKeymap 的配置后即可关闭本窗口')
    print('   ------------------------------------------------------------------')

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
    helpPageHtml = data.pop('helpPageHtml', None)
    with open('../data/config.json', 'r+', encoding='utf-8') as f:
        json.dump(data, f, indent=4, ensure_ascii=False)
        f.truncate()
    script.generate(data)
    saveHelpPageHtml(helpPageHtml)
    return 'save config ok!'

@app.route('/execute', methods=['POST'])
def execute():
    command = request.get_json()
    # print(command)
    if command['type'] == 'run-program':
        # print(os.getcwd())
        val = command['value']
        if val[0] == 'bin/ahk.exe':
            val[1] = '../' + val[1]
        val[0] = '../' + val[0]
        # print(val)
        subprocess.Popen(val)
    return command

def dev_api():
    print_banner('http://127.0.0.1:12333')
    # os.environ['WERKZEUG_RUN_MAIN'] = 'true'    # 关掉 flask 启动消息
    app.run(host="127.0.0.1", port=12333, debug=True, threaded=True)

def pro_api(port=12333):
    app.run(host="127.0.0.1", port=port, debug=False, threaded=True)

def main():
    arg = '--server'
    if len(sys.argv) >= 2:
        arg = sys.argv[1]
    if (arg == '--server'):
        script_compiled = getattr(sys, 'frozen', False)
        if script_compiled:
            pro_api()
        else:
            dev_api()
    elif (arg == '--rain'):
        # 获取随机端口避免端口冲突
        # port = get_random_port()
        # url = f'http://127.0.0.1:{port}'

        # 启动后端服务
        # p = Process(target=pro_api, args=(port,))
        # p.start()
        # browser_open(url)

        from unimatrix import startRain
        startRain()

if __name__ == '__main__':
    try:
        main()
    except Exception as e:
        error_log = traceback.format_exc()
        with open('error.txt', 'a') as f:
            f.write('\n')
            f.write(str(error_log))
        print(error_log)
        sys.exit(1)


# python 中文主机名 bug
# https://blog.csdn.net/qq_38161040/article/details/119416321
# getfqdn() 这个方法是为了获取包含域名的计算机名,  当主机名包含中文时这个函数会报错
# 简单的解决办法是修改主机名不包含中文,  但我不可能让用户去改主机名呀,  太不友好了
# 所以修改 socket.py 的 getfqdn() 的源码:
# 整个函数包一个 try-except, 加一个降级逻辑,  如果 gethostbyaddr() 报错则只返回 gethostname()
'''
    try:
        return gethostbyaddr()
    except Exception as e:
        print(e)
        return gethostname()
''' 

