import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios';
import { host, executeScript, emptyKeymap, ALL_KEYMAPS, NEW_CONFIGURABLE_KEYS, KEYMAP_PLUS_ABBR, emptyKeyConfig } from '../util.js';
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

function containsKeymap(data) {
  if (!data) return false
  for (const [key, value] of Object.entries(data)) {
    if (value && value['2'] && value['2'].value) return true;
  }
  return false
}

function processConfig(config) {
  config['CapslockAbbrKeys'] = Object.keys(config.CapslockAbbr)
  config['SemicolonAbbrKeys'] = Object.keys(config.SemicolonAbbr)
  // 逗号开头的放在前面
  config['CapslockAbbrKeys'] = _.concat(_.remove(config['CapslockAbbrKeys'], x => x.startsWith(',')), config['CapslockAbbrKeys'])
  config['SemicolonAbbrKeys'] = _.concat(_.remove(config['SemicolonAbbrKeys'], x => x.startsWith(',')), config['SemicolonAbbrKeys'])
  // 路径变量不要空行
  config['pathVariables'] = _.filter(config['pathVariables'], x => x.key && x.value)

  const s = config.Settings
  s['Mode3'] = s.enableMode3 && containsKeymap(config.Mode3)
  s['Mode9'] = s.enableMode9 && containsKeymap(config.Mode9)
  s['JMode'] = s.enableJMode && containsKeymap(config.JMode)
  s['CapslockMode'] = s.enableCapslockMode && containsKeymap(config.Capslock)
  s['SemicolonMode'] = s.enableSemicolonMode && containsKeymap(config.Semicolon)
  s['LButtonMode'] = s.enableLButtonMode && containsKeymap(config.LButtonMode)
  s['RButtonMode'] = s.enableRButtonMode && containsKeymap(config.RButtonMode)
  s['SpaceMode'] = s.enableSpaceMode && containsKeymap(config.SpaceMode)
  s['TabMode'] = s.enableTabMode && containsKeymap(config.TabMode)
  s['CommaMode'] = s.enableCommaMode && containsKeymap(config.CommaMode)
  
  if (!config['otherInfo']) {
    config['otherInfo'] = {}
  }
  const otherInfo = config['otherInfo']
  otherInfo['KEYMAP_PLUS_ABBR'] = KEYMAP_PLUS_ABBR

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
  },
  mutations: {
    SET_CONFIG(state, value) {
      console.log('fetch config', value)
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
          console.log(resp.data)
          store.commit('SET_SNACKBAR', { snackbar: true, snackbarText: `保存成功, 可按 alt+' 重启 MyKeymap` })
          // 自动重启 MyKeymap 体验并不好,  容易误触发大小写切换
          // executeScript('bin/ReloadAtSave.ahk')
        })
        .catch(error => {
          store.commit('SET_SNACKBAR', { snackbar: true, snackbarText: `保存失败` })
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
          resp.data.windowSelectors = resp.data.windowSelectors || [{id: '3', key: 'IntelliJ IDEA', value: 'ahk_exe idea64.exe'}]
          addExtendedKeys(resp.data, resp.data.supportPerAppConfig)

          // 这里不能用 || 语法,  因为要判断值是否 undefined 而不是判断值是否 falsy
          if (resp.data.Settings.enableCapslockAbbr === undefined) {
            resp.data.Settings.enableCapslockAbbr = true
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