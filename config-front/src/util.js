import axios from 'axios'

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

export function notEmptyAction(action) {
    return action.type != '什么也不做' && action.value
}

export const host = process.env.NODE_ENV === 'production' ? 'http://localhost:12333' : 'http://localhost:12333'

export function executeScript(arg) {
    axios.post(`${host}/execute`, {
        type: 'run-program',
        value: ['bin/ahk.exe', arg],
    })
}