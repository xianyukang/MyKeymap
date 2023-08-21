import { defineStore } from "pinia"
import { useFetch } from '@vueuse/core'
import { computed } from "vue"
import { useRoute } from "vue-router"

interface Config {
  keymaps: Keymap[]
}

interface Keymap {
  id: number
  name: string
  enable: boolean
}


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

  return { isFetching, config: data, error, enabledKeymaps, keymap }
})