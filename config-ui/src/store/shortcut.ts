import { defineStore } from 'pinia'
import { ref, watch } from 'vue'
import { useMyFetch } from './server'

interface Shortcut {
  path: string
}

export const useShortcutStore = defineStore('shortcut', () => {
  const shortcuts = fetchShortcuts()
  return { shortcuts }
})

const fetchShortcuts = () => {
  const shortcuts = ref<string[]>()
  const { data, error } = useMyFetch('/shortcuts').json<Shortcut[]>()
  watch(data, (newValue) => shortcuts.value = newValue?.map(x => x.path))
  return shortcuts
}
