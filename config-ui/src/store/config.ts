import { defineStore } from "pinia"
import { useFetch } from '@vueuse/core'
import { computed, ref } from "vue"
import { useRoute } from "vue-router"

export const useConfigStore = defineStore('config', () => {
  const url = 'http://localhost:12333/config'
  const { isFetching, data, error } = useFetch(url).json<Config>()

  const enabledKeymaps = computed(() => {
    return data.value?.keymaps.filter(x => x.enable)
  })

  const route = useRoute()
  const keymap = computed(() => {
    return data.value?.keymaps.find(x => x.id + '' === route.params.id)
  })

  // 根据选中的 hotkey 和 windowGroupID, 返回对应的 action
  const hotkey = ref("")
  const windowGroupID = ref(0)
  const action = computed(() => getAction(keymap.value, hotkey.value, windowGroupID.value))

  return { isFetching, config: data, error, enabledKeymaps, keymap, hotkey, windowGroupID, action }
})


function getAction(keymap: Keymap | undefined, hotkey: string, windowGroupID: number): Action | null {
  if (!keymap || !hotkey) {
    return null
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
    found = { windowGroupID: windowGroupID }
    actions.push(found)
  }
  return found
}



interface Config {
  keymaps: Keymap[]
}

interface Keymap {
  id: number
  name: string
  enable: boolean
  hotkeys: Hotkeys
}

interface Hotkeys {
  [key: string]: Action[]
}

interface Action {
  windowGroupID: number
  actionTypeID?: number
}