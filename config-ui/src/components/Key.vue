<script lang="ts" setup>
import { computed } from "vue";
import { trimStart, capitalize } from 'lodash-es';
import { Action, useConfigStore } from "@/store/config";

const store = useConfigStore()
const props = defineProps<{
  hotkey: string;
}>();

const keyText = computed(() => capitalize(trimStart(props.hotkey, '*')))
const keyColor = computed(() => hotkeyColor(store.keymap!.hotkey, props.hotkey, store.hotkey, store.getAction(props.hotkey)))
function click(hotkey: string) {
  store.hotkey = hotkey
}

function hotkeyColor(keymapHotkey: string, key: string, currentHotkey: string, action: Action): any {
  if (disabled(keymapHotkey, key)) {
    return { color: '#AAA', dark: true }
  }
  if (key === currentHotkey) {
    return { color: 'blue', dark: true }
  }
  if (action.actionTypeID) {
    return { color: '#98FB98', dark: false }
  }
  return {}
}

function width(key: string): number {
  if (key.length > 1) {
    return key.length * 10 + 40
  }
  return 53;
}

function disabled(keymapHotkey: string, hotkey: string): boolean {
  return keymapHotkey === hotkey
}
</script>

<template>
  <v-card v-bind="props"
          class="key"
          height="53"
          style="transition: none;"
          elevation="4"
          :width="width(keyText)"
          :color="keyColor.color"
          :dark="keyColor.dark"
          :disabled="disabled(store.keymap!.hotkey, hotkey)"
          @click="click(hotkey)"
          :class="['d-flex justify-center align-center']">
    <div>{{ keyText }}</div>
  </v-card>
</template>

<style scoped>
.key {
  /* border: 1px solid #999; */
  font-size: 1.5em;
  cursor: pointer;
}
</style>
