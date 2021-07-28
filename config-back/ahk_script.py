from codecs import BOM_UTF8
from jinja2 import Environment, FileSystemLoader


class AhkScript:
    def __init__(self):
        super().__init__()
        self.env = Environment(
            loader=FileSystemLoader("templates"), 
            variable_start_string='{{{', 
            variable_end_string='}}}',
            comment_start_string= '{##',
            comment_end_string= '##}',
            lstrip_blocks=True,
            trim_blocks=True,
            )
        self.env.filters['ahkString'] = self.ahkString
    
    @staticmethod
    def escapeAhkHotkey(key):
        if (key == ';'): 
            return '`;'
        return key

    @staticmethod
    def ahkString(s):
        s = s.replace('"',  '""')
        return '"' + s + '"'

    def makeCapslock(self, data):
        with open("../keymap/caps.ahk", "w+", encoding="utf-8-sig") as f:
            template = self.env.get_template("script.ahk")
            print(template.render(
                escapeAhkHotkey=self.escapeAhkHotkey,
                **data
                ), file=f)


if __name__ == "__main__":
    script = AhkScript()
    script.makeCapslock({})

    # 测试 utf-8 编码是否带 bom, ahk 脚本必须用带 bom 的 utf-8 编码
    with open("caps.ahk", "rb") as f:
        print(f.read(3) == BOM_UTF8)
