import { useFetch } from '@vueuse/core'
import { defineStore } from 'pinia'
import { ref, watch } from 'vue'

interface Shortcut {
  path: string
}

export const useShortcutStore = defineStore('shortcut', () => {
  const shortcuts = fetchShortcuts()
  return { shortcuts }
})

const fetchShortcuts = () => {
  const shortcuts = ref<string[]>()
  const url = 'http://localhost:12333/shortcuts'
  const { data, error } = useFetch(url).json<Shortcut[]>()
  watch(data, (newValue) => shortcuts.value = newValue?.map(x => x.path))
  return shortcuts
}
