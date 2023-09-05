import { defineStore } from "pinia"
import { useFetch } from '@vueuse/core'
import { computed, ref, watch } from "vue"
import { useRoute } from "vue-router"
import { Action, Config, Keymap } from "@/types/config";

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
    arr.unshift({ id: 0, name: "无", hotkey: "", parentID: 0, enable: true, hotkeys: {} })
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

  return {
    config, keymap, hotkey, windowGroupID, action, enabledKeymaps, customKeymaps, options, hotkeys,
    customParentKeymaps, customSonKeymaps, keymaps, changeActionComment, changeAbbrEnable,
    changeHotkey, removeHotkey, addHotKey,
    disabledKeys: computed(() => _disabledKeys(enabledKeymaps.value)),
    getAction: (hotkey: string) => _getAction(keymap.value, hotkey, windowGroupID.value),
    saveConfig: () => _saveConfig(config.value),
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
  }

  // 选择的 windowGroupID 还没有对应的 action, 那么初始化一下
  let found = actions.find(x => x.windowGroupID === windowGroupID)
  if (!found) {
    found = { ...emptyAction, windowGroupID }
    actions.push(found)
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
    for (const [hk, actions] of Object.entries(km.hotkeys)) {
      const filterd = actions.filter(x => !x.isEmpty)
      if (filterd.length > 0) {
        km.hotkeys[hk] = filterd
      } else {
        delete km.hotkeys[hk]
      }
    }
  }
  const { error } = useFetch("http://localhost:12333/config").put(config)
}

function _disabledKeys(keymaps: Keymap[]) {
  // 返回值为各个 keymap 该禁用的热键, 比如 {1: {"*3": true} }
  const m = {} as any
  for (const km of keymaps) {
    if (!m[km.id]) {
      m[km.id] = {}
    }
    m[km.id][km.hotkey] = true
    m[km.id]['*' + km.hotkey] = true

    if (!m[km.parentID]) {
      m[km.parentID] = {}
    }
    m[km.parentID][km.hotkey] = true
    m[km.parentID]['*' + km.hotkey] = true
  }
  return m
}

function fetchConfig() {
  const config = ref<Config>()
  const url = 'http://localhost:12333/config'
  const { data, error } = useFetch(url).json<Config>()
  watch(data, (newValue) => config.value = newValue!)
  return config
}
