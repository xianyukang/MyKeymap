import os
import subprocess
from codecs import BOM_UTF8
from template_engine import template_engine


class AhkScript:
    funcId = 0

    def __init__(self):
        super().__init__()
        self.env = template_engine

    @staticmethod
    def ifBranch(selId, windowSelector, value):
        value = value.lstrip('\n')
        value = value.rstrip(' ')
        value = value.rstrip('\n')
        value = '\n'.join(['        ' + x.lstrip() for x in value.split('\n') if x])

        if selId == '2':
            return f'    if (true) {{\n{value}\n        return\n    }}'
        return f'    if winactive("{windowSelector}") {{\n{value}\n        return\n    }}'

    @staticmethod
    def keyConfigToAhkFunc(keyConfig, keymapName, windowSelectors):
        """把一个键的配置转成一个 ahk 函数"""

        branches = []
        for sel in windowSelectors:
            selId = sel['id']
            if keyConfig.get(selId) and keyConfig.get(selId).get('value'):
                branches.append(AhkScript.ifBranch(selId, sel['value'], keyConfig.get(selId).get('value')))
            

        funcName = keymapName + '__' + str(AhkScript.funcId)
        body = '\n'.join(branches)
        funcDefinition = f'{funcName}()\n{{\n{body}\n}}'
        if not body:
            funcDefinition = ''
            
        return funcName, funcDefinition

    @staticmethod
    def processData(config):        
        all_ahk_funcs = []
        windowSelectors = config['windowSelectors']
        windowSelectors.append({'id': '2', 'value': 'USELESS'}) 

        # 遍历每一个模式的每一个键的配置
        for keymapName in config['otherInfo']['KEYMAP_PLUS_ABBR']:
            keymap = config[keymapName]
            for keyName, keyConfig in keymap.items():
                # 按键没有分应用配置
                if len(keyConfig) == 1:
                    keymap[keyName] = keyConfig['2']
                else:
                    funcName, funcDefinition = AhkScript.keyConfigToAhkFunc(keyConfig, keymapName, windowSelectors)
                    if funcDefinition:
                        keymap[keyName]['value'] = funcName + '()'
                        keymap[keyName]['prefix'] = '*'
                        all_ahk_funcs.append(funcDefinition)
                    else:
                        keymap[keyName]['value'] = ''

                AhkScript.funcId = AhkScript.funcId + 1

        config['all_ahk_funcs'] = all_ahk_funcs
        return

    @staticmethod
    def escapeAhkHotkey(key):
        if (key == ';'): 
            return '`;'
        return key

    def generate(self, data):
        self.processData(data)
        data['SemicolonAbbrKeys'] = [ x.replace(",", ",,") for x in  data['SemicolonAbbrKeys']]
        data['CapslockAbbrKeys'] = [ x.replace(",", ",,") for x in  data['CapslockAbbrKeys']]
        data['MouseMoveMode'] = data[data['Settings']['MouseMoveMode']]
        with open("../bin/MyKeymap.ahk", "w+", encoding="utf-8-sig") as f:
            template = self.env.get_template("script.ahk")
            print(template.render(
                escapeAhkHotkey=self.escapeAhkHotkey,
                **data
                ), file=f)
            
            # old = os.getcwd()
            # os.chdir('..')
            # subprocess.Popen(['MyKeymap.exe'])
            # os.chdir(old)
        AhkScript.funcId = 0

if __name__ == "__main__":
    script = AhkScript()
    script.generate({})

    # 测试 utf-8 编码是否带 bom, ahk 脚本必须用带 bom 的 utf-8 编码
    # with open("xxx.ahk", "rb") as f:
    #     print(f.read(3) == BOM_UTF8)
