import { defineStore } from "pinia"
import { useFetch } from '@vueuse/core'
import { computed, ref, watch } from "vue"
import { useRoute } from "vue-router"

const emptyAction: Action = {
  windowGroupID: 0,
  actionTypeID: 0,
}

export const useConfigStore = defineStore('config', () => {
  const url = 'http://localhost:12333/config'
  const { isFetching, data: config, error } = useFetch(url).json<Config>()

  // 根据 url 返回对应的 keymap
  const route = useRoute()
  const keymap = ref<Keymap>()
  watch(
    () => config.value?.keymaps.find(x => x.id + '' === route.params.id),
    (newValue) => keymap.value = newValue
  )

  // 根据选中的 hotkey 和 windowGroupID, 返回对应的 action
  const hotkey = ref("")
  const windowGroupID = ref(0)
  const action = ref(emptyAction)
  watch(
    () => _getAction(keymap.value, hotkey.value, windowGroupID.value),
    (newValue) => action.value = newValue
  )

  return {
    isFetching, config, error, keymap, hotkey, windowGroupID, action,
    getAction: (hotkey: string) => _getAction(keymap.value, hotkey, windowGroupID.value),
    enabledKeymaps: computed(() => config.value?.keymaps.filter(x => x.enable)),
  }
})


function _getAction(keymap: Keymap | undefined, hotkey: string, windowGroupID: number): Action {
  if (!keymap || !hotkey) {
    return emptyAction
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
    found = emptyAction
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
  actionTypeID: number
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