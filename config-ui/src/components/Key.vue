<script lang="ts" setup>
import { computed } from "vue";
import trimStart from "lodash-es/trimStart";
import { useConfigStore } from "@/store/config";

const store = useConfigStore()
const props = defineProps<{
  hotkey: string;
  laber?: string;
}>();

const keyText = computed(() => {
  const string = trimStart(props.hotkey, '*')
  return string.charAt(0).toUpperCase() + string.slice(1)
})
const keyColor = computed(() => {
  if (store.hotkey === props.hotkey) {
    return 'blue'
  }
  if (store.keymap?.hotkey.includes("Abbr")) {
    return ''
  }
  if (!store.getAction(props.hotkey).isEmpty) {
    return '#98FB98'
  }
  return ''
})

const disabled = computed(() => {
  return store.disabledKeys[store.keymap!.id][props.hotkey.toLowerCase()]
})

function click(hotkey: string) {
  store.hotkey = hotkey
}

function width(key: string): number {
  if (key.length > 1) {
    return key.length * 10 + 40
  }
  return 53;
}

</script>

<template>
  <v-hover v-slot:default="{ isHovering, props }">
    <v-card v-bind="props"
            height="53"
            style="transition: none; font-size: 1.5rem;"
            :elevation="isHovering ? 13 : 4"
            :width="width(keyText) + (isHovering ? 1 : 0)"
            :color="disabled ? '#AAA' : keyColor"
            :disabled="disabled"
            @click="click(hotkey)"
            :class="['d-flex justify-center align-center']">
      <div>{{ laber ?? keyText }}</div>
    </v-card>
  </v-hover>
</template>

<style scoped>
/* 鼠标在 card 之上 hover 时 vuetify 会加一个变暗遮罩, 去掉这个东西 */
:deep(.v-card__overlay) {
  background-color: unset;
}
</style>
