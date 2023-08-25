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

function hotkeyColor(keymapHotkey: string, key: string, currentHotkey: string, action: Action): string {
  if (disabled(keymapHotkey, key)) {
    return '#AAA'
  }
  if (key === currentHotkey) {
    return 'blue'
  }
  if (action.actionTypeID) {
    return '#98FB98'
  }
  return ''
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
  <v-hover v-slot:default="{ isHovering, props }">
    <v-card v-bind="props"
            height="53"
            style="transition: none; font-size: 1.5rem;"
            :elevation="isHovering ? 13 : 4"
            :width="width(keyText) + (isHovering ? 1 : 0)"
            :color="keyColor"
            :disabled="disabled(store.keymap!.hotkey, hotkey)"
            @click="click(hotkey)"
            :class="['d-flex justify-center align-center']">
      <div>{{ keyText }}</div>
    </v-card>
  </v-hover>
</template>

<style scoped>
/* 鼠标在 card 之上 hover 时 vuetify 会加一个变暗遮罩, 去掉这个东西 */
:deep(.v-card__overlay) {
  background-color: unset;
}
</style>
