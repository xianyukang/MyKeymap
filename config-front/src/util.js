import axios from 'axios'
import _ from 'lodash'

// export function fetchConfig() {
//     return axios.get('http://localhost:8000/config')
//         .then(resp => resp.data)
//         .catch(error => {
//             throw error // 方便后面看堆栈定位问题
//         })
// }

// 获取当前页面对应的配置的 mixin
export const currConfigMixin = {
    methods: {
        currConfig() {
            return this.$store.state.config[this.$route.name]
        },
    },
}

// 用户输入的字符串可能包含双引号,  不做处理的话, 会导致 ahk 脚本语法错误
export function escapeFuncString(arg) {
    if (!arg) return ''
    return arg.replaceAll('"', '""')
}

export function notBlank(str) {
    return str && str.trim().length > 0
}

// 所有的按键映射
export const ALL_KEYMAPS = [
    'Capslock',
    'CapslockF',
    'Mode3',
    'Mode9',
    'CapslockSpace',
    'SpaceMode',
    'JMode',
    'JModeK',
    'TabMode',
    'Semicolon',
    'RButtonMode',
    'LButtonMode',
    'CommaMode',
    'DotMode',
]
// 所有的按键映射 + 缩写功能
export const KEYMAP_PLUS_ABBR = [
    ...ALL_KEYMAPS,
    'CapslockAbbr',
    'SemicolonAbbr',
    'CustomHotkeys',
    'SpecialKeys',
]


export const getKeymapName = {
    "Capslock": "Capslock",
    "CapslockF": "Capslock + F",
    "CapslockSpace": "Capslock + Space",
    "CapslockAbbr": "Capslock 指令",
    "TabMode": "Tab 模式",
    "SpaceMode": "空格模式",
    "JMode": "J 模式",
    "JModeK": "J + K 模式",
    "CommaMode": "逗号模式",
    "DotMode": "句号模式",
    "Semicolon": "分号模式",
    "SemicolonAbbr": "分号缩写",
    "Mode3": "3 模式",
    "Mode9": "9 模式",
    "LButtonMode": "鼠标左键",
    "RButtonMode": "鼠标右键",
    "Settings": "开关/设置",
    "CustomHotkeys": "自定义热键",
}


export function isModeEnabled(mode, settings) {
    if (mode.startsWith('Capslock')) {
        if (mode.startsWith('CapslockAbbr')) {
            return true
        }
        if (mode.startsWith('CapslockF')) {
            return settings['enableCapslockMode'] && settings['enableCapsF']
        }
        if (mode.startsWith('CapslockSpace')) {
            return settings['enableCapslockMode'] && settings['enableCapsSpace']
        }
        return settings['enableCapslockMode']
    }
    if (mode.startsWith('Semicolon')) {
        if (mode.startsWith('SemicolonAbbr')) {
            return true
        }
        return settings['enableSemicolonMode']
    }
    if (mode.startsWith('SpaceMode')) {
        return settings['enableSpaceMode']
    }
    if (mode.startsWith('JMode')) {
        return settings['enableJMode']
    }
    if (mode.startsWith('Mode3')) {
        return settings['enableMode3']
    }
    if (mode.startsWith('Mode9')) {
        return settings['enableMode9']
    }
    if (mode.startsWith('LButtonMode')) {
        return settings['enableLButtonMode']
    }
    if (mode.startsWith('RButtonMode')) {
        return settings['enableRButtonMode']
    }
    if (mode.startsWith('TabMode')) {
        return settings['enableTabMode']
    }
    if (mode.startsWith('CommaMode')) {
        return settings['enableCommaMode']
    }
    if (mode.startsWith('DotMode')) {
        return settings['enableDotMode']
    }
    return true
}

export const EMPTY_KEY = 'EMPTY_KEY';
export const NEW_CONFIGURABLE_KEYS = [
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
]


// 转义文本中的 ahk 特殊字符
function ahkText(s) {
    s = s.replaceAll('`', '``')
    s = s.replaceAll('%', '`%')
    s = s.replaceAll(';', '`;')

    // 全是空格
    if (_.trim(s, ' ') === '') {
        return _.repeat('` ', s.length + 1)
    }
    // 保留两端空格
    let temp = _.trimStart(s, ' ')
    if (s.length !== temp.length) {
        s = _.repeat('` ', s.length - temp.length) + temp
    }
    temp = _.trimEnd(s, ' ')
    if (s.length !== temp.length) {
        s = temp + _.repeat('` ', s.length - temp.length + 1)
    }

    return s
}

// 映射一行要发送的按键
export function mapKeysToSend(line) {
    line = _.trimStart(line)
    if (line.startsWith(';') || line.startsWith('sleep') || line.startsWith('Sleep')) {
        return '    ' + line
    }
    if (line.startsWith('{text}') || line.startsWith('{Text}')) {
        line = ahkText(line)
    }
    return '    send, {blind}' + line
}

function escapeRegExp(string) {
    return string.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'); // $& means the whole matched string
}


export function uniqueName(ctx, key) {
    const symbolList = ' !"#$%&\'()*+,-./:;<=>?@[\\]^`{|}~';
    for (const c of symbolList) {
        key = key.replace(new RegExp(escapeRegExp(c), "g"), c.charCodeAt(0))
    }
    return ctx + '__' + key
}

export function bindWindow(ctx, key) {
    const var_name = uniqueName(ctx, key)
    return `bindOrActivate(${var_name})`
}


export function notEmptyAction(action) {
    return action.type != '什么也不做' && action.value
}

// 魔法: 用 localhost 访问 flask 会有 300ms 延迟,  用 127.0.0.1 则只要 5ms ...
export const host = process.env.NODE_ENV === 'production' ? 'http://127.0.0.1:12333' : 'http://127.0.0.1:12333'

export function executeScript(arg) {

    let value = ['bin/ahk.exe', arg]
    if (Array.isArray(arg)) {
        value = ['bin/ahk.exe', ...arg]
    }

    axios.post(`${host}/execute`, {
        type: 'run-program',
        value
    })
}

export function emptyKeyConfig(supportPerAppConfig) {
    if (supportPerAppConfig) {
        return {
            '2': {
                "type": "什么也不做",
                "value": ""
            }
        }
    }
    return {
        "type": "什么也不做",
        "value": ""
    }
}

export function emptyKeymap(supportPerAppConfig) {
    const km = {
        "Space": emptyKeyConfig(supportPerAppConfig),
        "Q": emptyKeyConfig(supportPerAppConfig),
        "W": emptyKeyConfig(supportPerAppConfig),
        "E": emptyKeyConfig(supportPerAppConfig),
        "R": emptyKeyConfig(supportPerAppConfig),
        "T": emptyKeyConfig(supportPerAppConfig),
        "Y": emptyKeyConfig(supportPerAppConfig),
        "U": emptyKeyConfig(supportPerAppConfig),
        "I": emptyKeyConfig(supportPerAppConfig),
        "O": emptyKeyConfig(supportPerAppConfig),
        "P": emptyKeyConfig(supportPerAppConfig),
        "A": emptyKeyConfig(supportPerAppConfig),
        "S": emptyKeyConfig(supportPerAppConfig),
        "D": emptyKeyConfig(supportPerAppConfig),
        "F": emptyKeyConfig(supportPerAppConfig),
        "G": emptyKeyConfig(supportPerAppConfig),
        "H": emptyKeyConfig(supportPerAppConfig),
        "J": emptyKeyConfig(supportPerAppConfig),
        "K": emptyKeyConfig(supportPerAppConfig),
        "L": emptyKeyConfig(supportPerAppConfig),
        ";": emptyKeyConfig(supportPerAppConfig),
        "Z": emptyKeyConfig(supportPerAppConfig),
        "X": emptyKeyConfig(supportPerAppConfig),
        "C": emptyKeyConfig(supportPerAppConfig),
        "V": emptyKeyConfig(supportPerAppConfig),
        "B": emptyKeyConfig(supportPerAppConfig),
        "N": emptyKeyConfig(supportPerAppConfig),
        "M": emptyKeyConfig(supportPerAppConfig),
        ",": emptyKeyConfig(supportPerAppConfig),
        ".": emptyKeyConfig(supportPerAppConfig),
        "/": emptyKeyConfig(supportPerAppConfig)
    }

    return km
}