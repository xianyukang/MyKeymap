import { defineStore } from "pinia"
import { computed, ref, watch } from "vue"
import { useRoute } from "vue-router"
import { Action, Config, Keymap } from "@/types/config";
import { useMyFetch } from "./server";
import trimStart from "lodash-es/trimStart";
import { languageMap } from "./language-map";
import { useThrottleFn } from "@vueuse/core";


const defaultKeyboardLayout = "1 2 3 4 5 6 7 8 9 0\nq w e r t y u i o p\na s d f g h j k l ;\nz x c v b n m , . /\nspace enter backspace - [ ' singlePress"
const keyboardLayout74 = "esc f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12\n` 1 2 3 4 5 6 7 8 9 0 - = backspace\ntab q w e r t y u i o p [ ] \\\ncapslock a s d f g h j k l ; ' enter\nLShift z x c v b n m , . / RShift\nLCtrl LWin LAlt space RAlt RWin RCtrl singlePress"
const keyboardLayout104 = "esc f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12\n` 1 2 3 4 5 6 7 8 9 0 - = backspace\ntab q w e r t y u i o p [ ] \\\ncapslock a s d f g h j k l ; ' enter\nLShift z x c v b n m , . / RShift\nLCtrl LWin LAlt space RAlt RWin RCtrl singlePress\nPrintScreen ScrollLock Pause insert home pgup delete end pgdn up down left right\nnumpad0 numpad1 numpad2 numpad3 numpad4 numpad5 numpad6 numpad7 numpad8 numpad9\nNumpadDot NumpadEnter NumpadAdd NumpadSub NumpadMult NumpadDiv NumLock"
const mouseButtons = "LButton RButton MButton XButton1 XButton2 WheelUp WheelDown WheelLeft WheelRight"

export const useConfigStore = defineStore('config', () => {
  // 根据 url 返回对应的 keymap
  const config = fetchConfig()
  const route = useRoute()
  const keymap = ref<Keymap>()
  watch(
    () => config.value?.keymaps.find(x => x.id + '' === route.params.id),
    (newValue) => {
      keymap.value = newValue
      hotkey.value = "" // 防止串键, 会导致当前选择的键带到缩写模式中
    }
  )

  // 根据选中的 hotkey 和 windowGroupID, 返回对应的 action
  const hotkey = ref("")
  const windowGroupID = ref(0)
  const action = ref({ ...emptyAction })
  watch(
    () => _getAction(keymap.value, hotkey.value, windowGroupID.value),
    (newValue) => action.value = newValue
  )

  watch(() => [action.value.actionTypeID, action.value.actionValueID],
    ([newTypeId, newValueId], [oldTypeid, oldValueId]) => {
      if ((newTypeId == 9 || oldTypeid == 9) && (newValueId == 5 || oldValueId == 5 || newValueId == 6 || oldValueId == 6)) {
        changeAbbrEnable()
      }
    }
  )

  function changeAbbrEnable() {
    // 获取缩写Keymap
    const capsAbbr = config.value!.keymaps[config.value!.keymaps.length - 3]
    const seemAbbr = config.value!.keymaps[config.value!.keymaps.length - 2]
    // 默认为关闭状态
    let capsAbbrEnable = false
    let seemAbbrEnable = false

    for (let km: Keymap of enabledKeymaps.value) {
      // 不遍历缩写、设置
      if (km.id >= 2 && km.id <= 4) {
        console.log(km.id)
        continue;
      }

      // 当两个缩写状态都为开启时不再遍历
      if (capsAbbrEnable && seemAbbrEnable) {
        break
      }

      for (let key: string in km.hotkeys) {
        for (let act: Action of km.hotkeys[key]) {
          // 有选择caps命令将命令状态设置为开启
          if (act.actionTypeID == 9 && act.actionValueID == 6) {
            capsAbbrEnable = true
            continue
          }

          // 有选择缩写将缩写状态设置为开启
          if (act.actionTypeID == 9 && act.actionValueID == 5) {
            seemAbbrEnable = true
          }
        }
      }
    }

    // 设置缩写的状态
    capsAbbr.enable = capsAbbrEnable
    seemAbbr.enable = seemAbbrEnable
  }

  const changeActionComment = (label: string) => {
    action.value.comment = label
  }

  const keymaps = computed(() => config.value!.keymaps)
  const options = computed(() => config.value!.options)

  const enabledKeymaps = computed(() => keymaps.value.filter(x => x.enable))
  const customKeymaps = computed(() => keymaps.value.filter(x => x.id > 4))
  const customSonKeymaps = computed(() => customKeymaps.value.filter(x => x.parentID != 0))
  const customParentKeymaps = computed(() => {
    const arr = customKeymaps.value.filter(x => x.parentID == 0)
    arr.unshift({ id: 0, name: "-", hotkey: "", parentID: 0, enable: true, hotkeys: {}, delay: 0 })
    return arr;
  })


  const hotkeys = computed(() => keymap.value?.hotkeys!)

  function changeHotkey(oldHotkey: string, newHotkey: string) {
    // 如果热键已存在且当前键的action.actionTypeID 为0删除当前热键,不为0删除之前的热键
    if (newHotkey in hotkeys.value) {
      if (hotkeys.value[oldHotkey][0].actionTypeID == 0) {
        removeHotkey(oldHotkey)
        return newHotkey
      } else {
        removeHotkey(newHotkey)
      }
    }

    // 如果直接替换会导致hotkey的位置在最下方
    keymap.value!.hotkeys = Object.keys(hotkeys.value).reduce((result: { [key: string]: Array<Action> }, key) => {
      if (key == oldHotkey) {
        result[newHotkey] = hotkeys.value[key];
      } else {
        result[key] = hotkeys.value[key];
      }
      return result;
    }, {})
  }

  function removeHotkey(hotkey: string) {
    delete hotkeys.value[hotkey]
  }

  function addHotKey(key: string = "") {
    keymap.value!.hotkeys[key] = [{ ...emptyAction }]
  }

  function resetKeyboardLayout(num: number) {
    if (num == 0) {
      options.value.keyboardLayout = defaultKeyboardLayout
    } else if (num == 74) {
      options.value.keyboardLayout = keyboardLayout74
    } else if (num == 104) {
      options.value.keyboardLayout = keyboardLayout104
    } else if (num == 1) {
      options.value.keyboardLayout += '\n' + mouseButtons
    }
  }

  function translate(comment: string) {
    const m = languageMap as any
    if (comment && comment.startsWith('label:')) {
      const id = comment.substring(6)
      if (m[id]) {
        return m[id][config.value!.options.language] ?? m[id]['en']
      }
    }
    return comment
  }

  return {
    config, keymap, hotkey, windowGroupID, action, enabledKeymaps, customKeymaps, options, hotkeys,
    customParentKeymaps, customSonKeymaps, keymaps, changeActionComment, changeAbbrEnable, resetKeyboardLayout,
    changeHotkey, removeHotkey, addHotKey, translate,
    disabledKeys: computed(() => _disabledKeys(enabledKeymaps.value)),
    getAction: (hotkey: string) => _getAction(keymap.value, hotkey, windowGroupID.value),
    saveConfig: useThrottleFn(() => _saveConfig(config.value), 1000),
  }
})

const emptyAction: Action = {
  windowGroupID: 0,
  actionTypeID: 0,
  isEmpty: true,
}

function _getAction(keymap: Keymap | undefined, hotkey: string, windowGroupID: number): Action {
  if (!keymap || !hotkey) {
    return { ...emptyAction }
  }

  // keymap 中此热键还不存在, 那么初始化一下
  let actions = keymap.hotkeys[hotkey]
  if (!actions) {
    actions = []
    keymap.hotkeys[hotkey] = actions
    // 比如新增了 2 模式, 让它的 singlePress 默认为输入 2 键
    if (keymap.isNew && hotkey == 'singlePress') {
      console.log('singlePress')
      const key = trimStart(keymap.hotkey, ' #!^+<>*~$')
      actions.push({
        windowGroupID: 0,
        actionTypeID: 6,
        isEmpty: false,
        keysToSend: '{blind}{' + key + '}',
        comment: '输入 ' + key + ' 键'
      })
    }
  }

  // 选择的 windowGroupID 还没有对应的 action, 那么初始化一下
  let found = actions.find(x => x.windowGroupID === windowGroupID)
  if (!found) {
    found = { ...emptyAction, windowGroupID }
    actions.push(found)
    actions.sort((a, b) => a.windowGroupID - b.windowGroupID)
  }
  return found
}

function _saveConfig(config: Config | undefined) {
  if (!config) {
    return
  }

  // 克隆一下, 然后删掉空的 action
  config = JSON.parse(JSON.stringify(config))
  for (const km of config!.keymaps) {
    const keySet = new Set(parseKeyboardLayout(config!.options.keyboardLayout, km.hotkey).flatMap(x => x))
    for (const [hk, actions] of Object.entries(km.hotkeys)) {
      const filterd = actions.filter(x => !x.isEmpty)
      const normalKeymap = km.id > 4
      if (filterd.length > 0 && (!normalKeymap || (normalKeymap && keySet.has(hk)))) {
        km.hotkeys[hk] = filterd
      } else {
        delete km.hotkeys[hk]
      }
    }
  }
  useMyFetch("/config", { timeout: 1500, })
    .put(config)
    .onFetchError(err => { 
      console.error(err)
      alert(`保存失败，可能设置程序被关了, ${err.name}:${err.code}`)
    }
  )
}

function _disabledKeys(keymaps: Keymap[]) {
  // 返回值为各个 keymap 该禁用的热键, 比如 {1: {"*3": true} }
  const m = {} as any
  for (const km of keymaps) {
    if (!m[km.id]) {
      m[km.id] = {}
    }
    m[km.id][km.hotkey.toLowerCase()] = true
    m[km.id]['*' + km.hotkey.toLowerCase()] = true

    if (!m[km.parentID]) {
      m[km.parentID] = {}
    }
    m[km.parentID][km.hotkey.toLowerCase()] = true
    m[km.parentID]['*' + km.hotkey.toLowerCase()] = true
  }
  return m
}

function fetchConfig() {
  const config = ref<Config>()
  const { data, error } = useMyFetch("/config").json<Config>()
  watch(data, (val) => {
    val = val!
    // 这个字段是后加的, 旧的 config.json 肯定没有此字段, 所以要初始化
    if (!val.options.keyboardLayout) {
      val.options.keyboardLayout = defaultKeyboardLayout
    }
    // 初始化语言
    if (!val.options.language) {
      if (navigator.language.includes('zh-')) {
        val.options.language = 'zh'
      } else {
        val.options.language = 'en'
      }
    }
    // 初始化排除列表
    if (val.options.windowGroups[0].id != -1) {
      val.options.windowGroups.unshift({
        id: -1,
        name: "🚫 Exclude",
        value: "",
      })
    }
    config.value = val
  })
  return config
}

export const parseKeyboardLayout = (layout: string, keymapHotkey: string) => {
  const rows = layout
    .split('\n')
    .filter(x => x.trim())
    .map(
      line => {
        const keys = line.split(/\s+/).filter(x => x.trim())
        return keys.map(key => {
          if (key == 'singlePress') {
            return key
          }
          return '*' + key
        })
      }
    )

  if (keymapHotkey.toLowerCase().includes("button")) {
    const list = rows.flatMap(x => x)
    const res = []
    if (!list.includes("*LButton")) { res.push("*LButton") }
    if (!list.includes("*MButton")) { res.push("*MButton") }
    if (!list.includes("*RButton")) { res.push("*RButton") }
    if (!list.includes("*WheelUp")) { res.push("*WheelUp") }
    if (!list.includes("*WheelDown")) { res.push("*WheelDown") }
    if (!list.includes("*XButton1")) { res.push("*XButton1") }
    if (!list.includes("*XButton2")) { res.push("*XButton2") }

    if (res.length > 0) {
      rows.push(res)
    }
  }
  return rows
}
