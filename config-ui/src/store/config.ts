import { defineStore } from "pinia"
import { useFetch } from '@vueuse/core'

interface Config {
  keymaps: Keymap[]
}

interface Keymap {
  id: number
  name: string
}


export const useConfigStore = defineStore('config', () => {
  const url = 'http://localhost:12333/config'
  const { isFetching, data, error } = useFetch<Config>(url).json()
  return { isFetching, config: data, error }
})