<script lang="ts" setup>
import { computed } from "vue";
import { useConfigStore } from "@/store/config";

const store = useConfigStore()
const props = defineProps<{
  hotkey: string;
  label: string;
}>();

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


</script>

<template>
  <v-hover v-slot:default="{ isHovering, props }">
    <v-card v-bind="props"
            height="50"
            style="transition: none; font-size: 1.5rem;"
            :elevation="isHovering ? 13 : 4"
            :color="disabled ? '#AAA' : keyColor"
            :disabled="disabled"
            @click="click(hotkey)"
            :class="['d-flex justify-center align-center' + (isHovering ? ' hover' : '')]">
      <div :class="label.length > 2 ? 'long-key' : 'key'">{{ label }}</div>
    </v-card>
  </v-hover>
</template>

<style scoped>
/* 鼠标在 card 之上 hover 时 vuetify 会加一个变暗遮罩, 去掉这个东西 */
:deep(.v-card__overlay) {
  background-color: unset;
}

.key {
  padding-left: 20px;
  padding-right: 20px;
}

.long-key {
  padding-left: 10px;
  padding-right: 10px;
}

.hover {
  margin-left: 1px;
}
</style>
