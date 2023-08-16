import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios';
import { host, executeScript, emptyKeymap, ALL_KEYMAPS, NEW_CONFIGURABLE_KEYS, KEYMAP_PLUS_ABBR, EMPTY_KEY, emptyKeyConfig, DefaultCustomShellMenu } from '../util.js';
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
  config['CapslockAbbrKeys'] = Object.keys(config.CapslockAbbr).map(x => x.replace(/,/g, ',,'))
  config['SemicolonAbbrKeys'] = Object.keys(config.SemicolonAbbr).map(x => x.replace(/,/g, ',,'))
  // 逗号开头的放在前面
  config['CapslockAbbrKeys'] = _.concat(_.remove(config['CapslockAbbrKeys'], x => x.startsWith(',')), config['CapslockAbbrKeys'])
  config['SemicolonAbbrKeys'] = _.concat(_.remove(config['SemicolonAbbrKeys'], x => x.startsWith(',')), config['SemicolonAbbrKeys'])
  // 路径变量不要空行
  config['pathVariables'] = _.filter(config['pathVariables'], x => x.key && x.value)
  // 收集发送按键的函数 (如果发送按键时写了多行,  会生成一个 ahk 函数包起来)
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
  if (s.AdditionalMode1Key === s.AdditionalMode2Key) { s.AdditionalMode2Key = "" }
  if (s.AdditionalMode1Info && s.AdditionalMode1Info.ClearKey) { config.AdditionalMode1[s.AdditionalMode1Info.ClearKey] = emptyKeyConfig(true) }
  if (s.AdditionalMode2Info && s.AdditionalMode2Info.ClearKey) { config.AdditionalMode2[s.AdditionalMode2Info.ClearKey] = emptyKeyConfig(true) }
  s['AdditionalMode1'] = !!s.AdditionalMode1Key && contains_one_valid_key(config.AdditionalMode1, ids)
  s['AdditionalMode2'] = !!s.AdditionalMode2Key && contains_one_valid_key(config.AdditionalMode2, ids)
  
  // 避免额外模式和按键重映射发生冲突
    function filter(remap, key) {
        if (!key || !remap) {
            return true
        }
        key = key.toLowerCase()
        remap = remap.toLowerCase()
        return !remap.startsWith(key)
    }
    s.KeyMapping = s.KeyMapping.split("\n").filter(remap => filter(remap, s.AdditionalMode1Key)).join("\n")
    s.KeyMapping = s.KeyMapping.split("\n").filter(remap => filter(remap, s.AdditionalMode2Key)).join("\n")

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
  let keyConfig = config.SpecialKeys["Caps Up"]
  if (!keyConfig["2"] && keyConfig.value ===  "enterCapslockAbbr()") {
    config.SpecialKeys["Caps Up"] = {
      "2": {
          "label": "Capslock 命令框",
          "type": "系统控制",
          "value": "enterCapslockAbbr()"
      }
    }
  }
  keyConfig = config.SpecialKeys["; Up"]
  if (!keyConfig["2"] && keyConfig.value ===  "enterSemicolonAbbr()") {
    config.SpecialKeys["; Up"] = {
      "2": {
          "label": "触发缩写功能",
          "type": "系统控制",
          "value": "enterSemicolonAbbr()"
      }
    }
  }

  if (config.Settings.KeyMapping === undefined) {
    config.Settings.KeyMapping = ""
  }
  if (config.Settings.mapRAltToCtrl) {
    config.Settings.mapRAltToCtrl = false
    config.Settings.KeyMapping = "RAlt::LCtrl"
  }
  if (config.Settings.CustomShellMenu === undefined) {
    config.Settings.CustomShellMenu = DefaultCustomShellMenu
  }
  if (config.Settings.windowSwitcherKeys === undefined) {
    config.Settings.windowSwitcherKeys = "E/D/S/F/X"
    config.Settings.windowSwitcherKeymap = `*E::send, {blind}{up}
*D::send, {blind}{down}
*S::send, {blind}{left}
*F::send, {blind}{right}
*X::send,  {blind}{del}
*Space::send, {blind}{enter}`
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

      // 当前键不存在,  比如键盘里新增了 WheelUp、F1 之类的键时
      let keymap = state.config[state.routeName]

      // 处理 Caps Up 之类的特殊键
      if (state.config.SpecialKeys[keyName]) {
        keymap = state.config.SpecialKeys
      }

      if (!keymap[keyName]) {
        Vue.set(keymap, keyName, {})
      }

      const currentKey = keymap[keyName]

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
          if (resp.data.Settings.exitMouseModeAfterClick === undefined) {
            resp.data.Settings.exitMouseModeAfterClick = true
          }
          if (resp.data.Settings.showMouseMovePrompt === undefined) {
            resp.data.Settings.showMouseMovePrompt = false
          }
          if (resp.data.Settings.AdditionalMode1Key === undefined) {
            resp.data.Settings.AdditionalMode1Key = ""
          }
          if (resp.data.Settings.AdditionalMode2Key === undefined) {
            resp.data.Settings.AdditionalMode2Key = ""
          }
          // 升级窗口标识符
          upgradeWindowSelector(resp.data.windowSelectors)

          // 升级时, 新增以前没有的特殊键
          resp.data.SpecialKeys = resp.data.SpecialKeys || {}
          resp.data.SpecialKeys['Caps Up'] = resp.data.SpecialKeys['Caps Up'] || { type: "系统控制", label: "Capslock 命令框", value: "enterCapslockAbbr()" }
          resp.data.SpecialKeys['; Up'] = resp.data.SpecialKeys['; Up'] || { type: "系统控制", label: "触发缩写功能", value: "enterSemicolonAbbr()" }

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

          // 升级逻辑
          upgrade(resp.data)
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

function upgradeWindowSelector(windowSelectors) {
    for (const sel of windowSelectors) {
        if (!sel.groupName) {
            const name = "window_group_" + sel.id
            sel.groupName = name
            sel.groupCode = ""
            if (sel.value.trim()) {
                sel.groupCode = `GroupAdd, ${name}, ${sel.value}`
            }
        }
    }
}