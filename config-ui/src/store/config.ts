import { defineStore } from "pinia"
import { useFetch } from '@vueuse/core'
import { computed, ref } from "vue"
import { useRoute } from "vue-router"

export const useConfigStore = defineStore('config', () => {
  const url = 'http://localhost:12333/config'
  const { isFetching, data, error } = useFetch(url).json<Config>()

  const enabledKeymaps = computed(() => {
    return data.value!.keymaps.filter(x => x.enable)
  })

  const route = useRoute()
  const keymap = computed(() => {
    return data.value!.keymaps.find(x => x.id + '' === route.params.id)!
  })

  // 根据选中的 hotkey 和 windowGroupID, 返回对应的 action
  const hotkey = ref("")
  const windowGroupID = ref(0)
  const action = computed(() => _getAction(keymap.value, hotkey.value, windowGroupID.value))

  function getAction(hotkey: string) {
    return _getAction(keymap.value, hotkey, windowGroupID.value)
  }

  return { isFetching, config: data, error, enabledKeymaps, keymap, hotkey, windowGroupID, action, getAction }
})


function _getAction(keymap: Keymap, hotkey: string, windowGroupID: number): Action {
  // keymap 中此热键还不存在, 那么初始化一下
  let actions = keymap.hotkeys[hotkey]
  if (!actions) {
    actions = []
    keymap.hotkeys[hotkey] = actions
  }

  // 选择的 windowGroupID 还没有对应的 action, 那么初始化一下
  let found = actions.find(x => x.windowGroupID === windowGroupID)
  if (!found) {
    found = { windowGroupID: windowGroupID, actionTypeID: 0 }
    actions.push(found)
  }
  return found
}



interface Config {
  keymaps: Keymap[]
  options: Options
}

export interface Keymap {
  id: number
  name: string
  enable: boolean
  hotkey: string
  hotkeys: Hotkeys
  extraHotkeys: string[]
}

interface Hotkeys {
  [key: string]: Action[]
}

export interface Action {
  windowGroupID: number
  actionTypeID?: number
}

interface Options {
  windowGroups: WindowGroup[]
}

interface WindowGroup {
  id: number
  name: string
  value: string
  conditionType: number
}