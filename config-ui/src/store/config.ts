import { defineStore } from "pinia"
import { useFetch } from '@vueuse/core'
import { computed, ref, watch } from "vue"
import { useRoute } from "vue-router"

export const useConfigStore = defineStore('config', () => {

  const config = initConfig()

  function initConfig() {
    const config = ref<Config>()
    const url = 'http://localhost:12333/config'
    const { data, error } = useFetch(url).json<Config>()
    watch(data, (newValue) => config.value = newValue!)
    return config
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
  const action = ref({ ...emptyAction })
  watch(
    () => _getAction(keymap.value, hotkey.value, windowGroupID.value),
    (newValue) => action.value = newValue
  )
  // TODO: 路由变化时把选中的 hotkey 清空
  const keymaps = computed(() => config.value!.keymaps)
  const options = computed(() => config.value!.options)

  const enabledKeymaps = computed(() => keymaps.value.filter(x => x.enable))
  const customKeymaps = computed(() => keymaps.value.filter(x => canEditKeymap(x)))
  const customSonKeymaps = computed(() => customKeymaps.value.filter(x => x.parentID != 0))
  const customParentKeymaps = computed(() => {
    const arr = customKeymaps.value.filter(x => x.parentID == 0)
    arr.unshift({ id: 0, name: "-", hotkey: "", parentID: 0, enable: true, hotkeys: {} })
    return arr;
  })

  const customHotkey = computed(() => enabledKeymaps.value[enabledKeymaps.value.length - 4].hotkeys)

  function getKeymapById(id: number) {
    return customParentKeymaps.value.find(k => k.id == id)!
  }

  function toggleKeymapEnable(keymap: Keymap) {
    // 开启的keymap有前置键连同前置键一块开启
    if (!keymap.enable && keymap.parentID != 0) {
      customParentKeymaps.value.find(k => k.id == keymap.parentID)!.enable = true
    }

    keymap.enable = !keymap.enable
  }

  function canEditKeymap(keymap: Keymap) {
    return keymap.id > 4
  }

  function nextKeymapId() {
    const length = customKeymaps.value.length;
    if (length == 0) {
      return 5
    }

    return customKeymaps.value[length - 1].id + 1
  }

  function addKeymap() {
    const newKeymap: Keymap = {
      id: nextKeymapId(),
      name: "",
      enable: false,
      hotkey: "",
      parentID: 0,
      hotkeys: {}
    }

    keymaps.value.splice(customKeymaps.value.length, 0, newKeymap)
  }

  function removeKeymap(id: number) {
    removeKeymapByIndex(keymaps.value.findLastIndex(k => k.id == id))
  }

  function removeKeymapByIndex(index: number) {
    keymaps.value.splice(index, 1)
  }

  function checkKeymapData(keymap: Keymap) {
    if (keymap.hotkey == "") {
      return keymap.id
    }
    // 判断当前热键是否已存在，已存在删除当前模式
    const f = keymaps.value.find(k => k.hotkey == keymap.hotkey && k.parentID == keymap.parentID)!
    if (f.id != keymap.id) {
      removeKeymap(keymap.id)
    }
    return f.id
  }

  return {
    config, keymap, hotkey, windowGroupID, action, enabledKeymaps, customKeymaps, options,
    getKeymapById, toggleKeymapEnable, canEditKeymap, customParentKeymaps, customSonKeymaps, addKeymap, removeKeymap,
    checkKeymapData,
    getAction: (hotkey: string) => _getAction(keymap.value, hotkey, windowGroupID.value),
    saveConfig: () => _saveConfig(config.value),
  }
})

const emptyAction: Action = {
  windowGroupID: 0,
  actionTypeID: 0,
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
    found = { ...emptyAction }
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
      const filterd = actions.filter(x => x.actionTypeID)
      if (filterd.length > 0) {
        km.hotkeys[hk] = filterd
      } else {
        delete km.hotkeys[hk]
      }
    }
  }
  const { error } = useFetch("http://localhost:12333/config").put(config)
}
