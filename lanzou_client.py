import json
import sys
try:
    from lanzou.api import LanZouCloud
except:
    print('missing package: pip3 install lanzou-api')
    exit(1)

def show_progress(file_name, total_size, now_size):
    """显示进度的回调函数"""
    percent = now_size / total_size
    bar_len = 40  # 进度条长总度
    bar_str = '>' * round(bar_len * percent) + '=' * round(bar_len * (1 - percent))
    print('\r{:.2f}%\t[{}] {:.1f}/{:.1f}MB | {} '.format(
        percent * 100, bar_str, now_size / 1048576, total_size / 1048576, file_name), end='')
    if total_size == now_size:
        print('')  # 下载完成换行


def handler(fid, is_file):
    if is_file:
        # lzy.set_desc(fid, '设置文件的描述', is_file=True)
        lzy.set_passwd(fid, '1234', is_file)
        info = lzy.get_share_info(fid, is_file)
        json.dump({'url': info.url, 'password': info.pwd}, sys.stderr)
        print('', file=sys.stderr)

def assertSuccess(code):
    if code != LanZouCloud.SUCCESS:
        raise RuntimeError("error code: " + str(code))

def login():
    with open('lanzou_cookie.txt', 'r') as f:
        lines = f.read().splitlines()
        cookie = {'ylogin': lines[0], 'phpdisk_info': lines[1]}
    code = lzy.login_by_cookie(cookie)
    assertSuccess(code)

if __name__ == '__main__':
    lzy = LanZouCloud()
    # 突然出现的 bug, 似乎换 ua 能解决: https://github.com/zaxtyson/LanZouCloud-API/issues/101
    lzy._headers["User-Agent"] = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/118.0.0.0 Safari/537.36"
    file = sys.argv[1]
    login()
    code = lzy.upload_file(file, -1, callback=show_progress, uploaded_handler=handler)
    assertSuccess(code)