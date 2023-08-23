import { defineStore } from "pinia"
import { useFetch } from '@vueuse/core'
import { computed, reactive, ref, watch } from "vue"
import { useRoute } from "vue-router"

export const useConfigStore = defineStore('config', () => {

  const config = initConfig()

  function initConfig() {
    const url = 'http://localhost:12333/config'
    const { data: config, error } = useFetch(url).json<Config>()
    return reactive(config)
  }

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

  const enabledKeymaps = computed(() => config.value!.keymaps.filter(x => x.enable))
  const customKeymaps = computed(() => config.value!.keymaps.filter(x => canEditKeymap(x)))

  function getKeymapById(id: number) {
    if (id == 0 || id == null) {
      return {
        id: 0,
        name: "-",
        hotkey: "",
        parentID: 0,
        enable: true,
        hotkeys: null
      }
    }

    return customKeymaps.value.find(k => k.id == id)!
  }

  function toggleKeymapEnable(keymap: Keymap) {
    keymap.enable = !keymap.enable
  }

  function canEditKeymap(keymap: Keymap) {
    return keymap.id > 4
  }

  return {
    config, keymap, hotkey, windowGroupID, action, enabledKeymaps, customKeymaps,
    getKeymapById, toggleKeymapEnable, canEditKeymap,
    getAction: (hotkey: string) => _getAction(keymap.value, hotkey, windowGroupID.value),
  }
})

const emptyAction: Action = {
  windowGroupID: 0,
  actionTypeID: 0,
  remapToKey: ""
}

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
