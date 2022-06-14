import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios';
import { host, executeScript, emptyKeymap, ALL_KEYMAPS, NEW_CONFIGURABLE_KEYS, KEYMAP_PLUS_ABBR, EMPTY_KEY, emptyKeyConfig } from '../util.js';
import _ from 'lodash'


Vue.use(Vuex)


function addExtendedKeys(data, supportPerAppConfig) {
  // 处理键盘中后来新增的可配置按键
  if (!data) return

  for (const km of ALL_KEYMAPS) {
    for (const k of NEW_CONFIGURABLE_KEYS) {
      if (data[km] && data[km][k] === undefined) {
        data[km][k] = emptyKeyConfig(supportPerAppConfig)
      }
    }
  }
}

function contains_one_valid_key(data, windowSelectorIds) {
  if (!data) return false
  for (const [key, value] of Object.entries(data)) {
    for (const sel of windowSelectorIds) {
      if (value && value[sel] && value[sel].value)
        return true;
    }
  }
  return false
}

function get_send_key_functions(config, windowSelectorIds) {
  const res = []
  for (const keymapName of KEYMAP_PLUS_ABBR) {
    for (const value of Object.values(config[keymapName])) {
      for (const sel of windowSelectorIds) {
        if (value && value[sel]) {
          if (value[sel].send_key_function) {
            res.push(value[sel].send_key_function)
          }
          if (sel !== '2' && !value[sel].value) {
            delete value[sel]   // 删掉无用配置
          }
        }
      }
    }
  }

  return res;
}

function processConfig(config) {
  const ids = ['2', ...config.windowSelectors.map(x => x.id)]
  config['CapslockAbbrKeys'] = Object.keys(config.CapslockAbbr)
  config['SemicolonAbbrKeys'] = Object.keys(config.SemicolonAbbr)
  // 逗号开头的放在前面
  config['CapslockAbbrKeys'] = _.concat(_.remove(config['CapslockAbbrKeys'], x => x.startsWith(',')), config['CapslockAbbrKeys'])
  config['SemicolonAbbrKeys'] = _.concat(_.remove(config['SemicolonAbbrKeys'], x => x.startsWith(',')), config['SemicolonAbbrKeys'])
  // 路径变量不要空行
  config['pathVariables'] = _.filter(config['pathVariables'], x => x.key && x.value)
  // 如果发送按键时写了多行,  则生成一个函数包起来
  config['send_key_functions'] = get_send_key_functions(config, ids)


  const s = config.Settings
  s['Mode3'] = s.enableMode3 && contains_one_valid_key(config.Mode3, ids)
  s['Mode9'] = s.enableMode9 && contains_one_valid_key(config.Mode9, ids)
  s['JMode'] = s.enableJMode && contains_one_valid_key(config.JMode, ids)
  s['CapslockMode'] = s.enableCapslockMode && contains_one_valid_key(config.Capslock, ids)
  s['SemicolonMode'] = s.enableSemicolonMode && contains_one_valid_key(config.Semicolon, ids)
  s['LButtonMode'] = s.enableLButtonMode && contains_one_valid_key(config.LButtonMode, ids)
  s['RButtonMode'] = s.enableRButtonMode && contains_one_valid_key(config.RButtonMode, ids)
  s['SpaceMode'] = s.enableSpaceMode && contains_one_valid_key(config.SpaceMode, ids)
  s['TabMode'] = s.enableTabMode && contains_one_valid_key(config.TabMode, ids)
  s['CommaMode'] = s.enableCommaMode && contains_one_valid_key(config.CommaMode, ids)
  s['DotMode'] = s.enableDotMode && contains_one_valid_key(config.DotMode, ids)

  // 如果开启了 Caps + F 模式,  那么 F 键的配置要清空
  if (s.enableCapsF) {
    config["Capslock"]["F"] = emptyKeyConfig(true)
  }
  if (s.enableCapsSpace) {
    config["Capslock"]["Space"] = emptyKeyConfig(true)
  }


  if (!config['otherInfo']) {
    config['otherInfo'] = {}
  }
  const otherInfo = config['otherInfo']
  otherInfo['KEYMAP_PLUS_ABBR'] = KEYMAP_PLUS_ABBR

  config['helpPageHtml'] = document.querySelector('#HelpPage').outerHTML

  return config
}

function upgrade(config) {
  // 把所有老配置放成全局生效
  for (const keymap of KEYMAP_PLUS_ABBR) {
    for (const [key, value] of Object.entries(config[keymap])) {
      config[keymap][key] = { '2': value }
    }
  }
}

const s = new Vuex.Store({
  state: {
    config: null,
    snackbar: false,
    snackbarText: '',
    routeName: '',
    windowSelector: '2',
    selectedKey: EMPTY_KEY,
  },
  getters: {
    config: (state) => (keyName) => {
      // 此函数返回当前选中的键关联的配置
      if (!keyName && state.selectedKey === EMPTY_KEY) {
        return { type: '什么也不做', value: '' }
      }

      keyName = keyName ? keyName : state.selectedKey;

      // 处理 Caps Up 之类的特殊键
      if (state.config.SpecialKeys[keyName]) {
        return state.config.SpecialKeys[keyName]
      }

      // 当前键不存在,  比如键盘里新增了 WheelUp、F1 之类的键时
      if (!state.config[state.routeName][keyName]) {
        Vue.set(state.config[state.routeName], keyName, {})
      }

      const currentKey = state.config[state.routeName][keyName]

      // 在某个窗口选择器下当前键没有配置,  则新增空白配置
      if (!currentKey[state.windowSelector]) {
        Vue.set(currentKey, state.windowSelector, { type: '什么也不做', value: '' })
      }

      return currentKey[state.windowSelector]
    },
  },
  mutations: {
    SET_CONFIG(state, value) {
      // console.log('fetch config', value)
      state.config = value
    },
    SET_SNACKBAR(state, { snackbar, snackbarText }) {
      state.snackbar = snackbar
      state.snackbarText = snackbarText
    },
  },
  actions: {
    saveConfig(store) {
      axios
        .put(`${host}/config`, processConfig(store.state.config))
        .then(resp => {
          // console.log(resp.data)
          store.commit('SET_SNACKBAR', { snackbar: true, snackbarText: `保存成功, 可按 alt+' 重启 MyKeymap` })
          // 自动重启 MyKeymap 体验并不好,  容易误触发大小写切换
          // executeScript('bin/ReloadAtSave.ahk')
        })
        .catch(error => {
          store.commit('SET_SNACKBAR', { snackbar: true, snackbarText: `保存失败, 可能是设置程序被关了` })
          throw error
        })
    },
    fetchConfig(store) {
      return axios.get(`${host}/config`)
        .then(resp => {
          for (const km of ALL_KEYMAPS) {
            if (!resp.data[km]) {
              resp.data[km] = emptyKeymap(resp.data.supportPerAppConfig)
            }
          }
          resp.data.windowSelectors = resp.data.windowSelectors || []
          addExtendedKeys(resp.data, resp.data.supportPerAppConfig)

          // 这里不能用 || 语法,  因为要判断值是否 undefined 而不是判断值是否 falsy
          if (resp.data.Settings.enableCapslockAbbr === undefined) {
            resp.data.Settings.enableCapslockAbbr = true
          }
          if (resp.data.Settings.enableCapsF === undefined) {
            resp.data.Settings.enableCapsF = true
          }
          if (resp.data.Settings.enableCapsSpace === undefined) {
            resp.data.Settings.enableCapsSpace = true
          }
          if (resp.data.Settings.enableCustomHotkeys === undefined) {
            resp.data.Settings.enableCustomHotkeys = true
          }
          if (resp.data.Settings.showMouseMovePrompt === undefined) {
            resp.data.Settings.showMouseMovePrompt = false
          }
          // 升级时, 新增以前没有的特殊键
          resp.data.SpecialKeys = resp.data.SpecialKeys || {}
          resp.data.SpecialKeys['Caps Up'] = resp.data.SpecialKeys['Caps Up'] || { type: "系统控制", label: "Capslock 指令框", value: "enterCapslockAbbr()" }
          resp.data.SpecialKeys['; Up'] = resp.data.SpecialKeys['; Up'] || { type: "系统控制", label: "缩写功能", value: "enterSemicolonAbbr()" }

          // 自定义热键功能
          resp.data.CustomHotkeys = resp.data.CustomHotkeys || {
            "!'": {
              "2": {
                "type": "系统控制",
                "value": "\nSuspend, Toggle\nReloadProgram()\nreturn",
                "label": "重启 MyKeymap"
              }
            },
            "+!'": {
              "2": {
                "type": "系统控制",
                "value": "\nSuspend, Permit\ntoggleSuspend()\nreturn",
                "label": "暂停 MyKeymap"
              }
            },
            "!capslock": {
              "2": {
                "type": "系统控制",
                "value": "toggleCapslock()",
                "label": "切换 Capslock 状态"
              }
            },
            "+capslock": {
              "2": {
                "type": "系统控制",
                "value": "toggleCapslock()",
                "label": "切换 Capslock 状态"
              }
            },
          }
          // 记录当前使用哪个模式移动鼠标
          if (resp.data.Settings.MouseMoveMode === undefined) {
            resp.data.Settings.MouseMoveMode = "Capslock"
          }

          // 从不支持分应用配置的版本升级
          if (resp.data.supportPerAppConfig === undefined) {
            upgrade(resp.data)
            resp.data.supportPerAppConfig = true
          }

          store.commit('SET_CONFIG', resp.data)
        })
        .catch(error => {
          throw error // 方便后面看堆栈定位问题
        })
    }
  },
  modules: {
  }
})
s.dispatch('fetchConfig')
export default s