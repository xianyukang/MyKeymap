import axios from 'axios'
import _ from 'lodash'

// export function fetchConfig() {
//     return axios.get('http://localhost:8000/config')
//         .then(resp => resp.data)
//         .catch(error => {
//             throw error // 方便后面看堆栈定位问题
//         })
// }

// 用户输入的字符串可能包含双引号,  不做处理的话, 会导致 ahk 脚本语法错误
export function escapeFuncString(arg) {
    if (!arg) return ''
    return arg.replaceAll('"', '""')
}

export function notBlank(str) {
    return str && str.trim().length > 0
}

export const ALL_KEYMAPS = [
    'Capslock',
    'CapslockF',
    'Mode3',
    'Mode3R',
    'Mode9',
    'CapslockSpace',
    'SpaceMode',
    'JMode',
    'JModeK',
    'JModeL',
    'TabMode',
    'Semicolon',
    'RButtonMode',
    'LButtonMode',
]
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
        return line
    }
    if (line.startsWith('{text}') || line.startsWith('{Text}')) {
        line = ahkText(line)
    }
    return 'send, {blind}' + line
}

export function bindWindow(ctx, key) {
    key = key === ';' ? 'semicolon' : key
    key = key === ',' ? 'comma' : key
    key = key === '.' ? 'dot' : key
    key = key === '/' ? 'slash' : key
    const var_name = ctx + '__' + key
    return `
    global ${var_name}
    bindOrActivate(${var_name})
    return`
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

export const emptyKeymap = {
    "Space": {
        "type": "什么也不做",
        "value": ""
    },
    "Q": {
        "type": "什么也不做",
        "value": ""
    },
    "W": {
        "type": "什么也不做",
        "value": ""
    },
    "E": {
        "type": "什么也不做",
        "value": ""
    },
    "R": {
        "type": "什么也不做",
        "value": ""
    },
    "T": {
        "type": "什么也不做",
        "value": ""
    },
    "Y": {
        "type": "什么也不做",
        "value": ""
    },
    "U": {
        "type": "什么也不做",
        "value": ""
    },
    "I": {
        "type": "什么也不做",
        "value": ""
    },
    "O": {
        "type": "什么也不做",
        "value": ""
    },
    "P": {
        "type": "什么也不做",
        "value": ""
    },
    "A": {
        "type": "什么也不做",
        "value": ""
    },
    "S": {
        "type": "什么也不做",
        "value": ""
    },
    "D": {
        "type": "什么也不做",
        "value": ""
    },
    "F": {
        "type": "什么也不做",
        "value": ""
    },
    "G": {
        "type": "什么也不做",
        "value": ""
    },
    "H": {
        "type": "什么也不做",
        "value": ""
    },
    "J": {
        "type": "什么也不做",
        "value": ""
    },
    "K": {
        "type": "什么也不做",
        "value": ""
    },
    "L": {
        "type": "什么也不做",
        "value": ""
    },
    ";": {
        "type": "什么也不做",
        "value": ""
    },
    "Z": {
        "type": "什么也不做",
        "value": ""
    },
    "X": {
        "type": "什么也不做",
        "value": ""
    },
    "C": {
        "type": "什么也不做",
        "value": ""
    },
    "V": {
        "type": "什么也不做",
        "value": ""
    },
    "B": {
        "type": "什么也不做",
        "value": ""
    },
    "N": {
        "type": "什么也不做",
        "value": ""
    },
    "M": {
        "type": "什么也不做",
        "value": ""
    },
    ",": {
        "type": "什么也不做",
        "value": ""
    },
    ".": {
        "type": "什么也不做",
        "value": ""
    },
    "/": {
        "type": "什么也不做",
        "value": ""
    }
}