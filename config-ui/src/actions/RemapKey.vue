<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import { watchEffect } from 'vue';
const { action, hotkey } = storeToRefs(useConfigStore())
const label = "重映射为 "
const items = [
  'up', 'down', 'left', 'right', 'home', 'end', 'backspace', 'delete',
  'space', 'tab', 'enter', 'esc', 'insert', 'capslock', 'appskey', 'pgup', 'pgdn',
  'LWin', 'RWin', 'LCtrl', 'RCtrl', 'LAlt', 'RAlt', 'LShift', 'RShift', 'PrintScreen',
  'volume_mute', 'volume_up', 'volume_down', 'media_next', 'media_prev', 'media_stop', 'media_play_pause',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12',
]

const errorMsg = "当前键不支持「 重映射 」，请使用「 输入文本或按键 」"

watchEffect(() => {
  action.value.isEmpty = !action.value.remapToKey
})

const changeComment = (key?: string) => {
  useConfigStore().changeActionComment(key ? label + key : "")
}

</script>

<template>
  <!-- :menu-props="{ maxHeight: '390px' }" 可以调整下拉框高度 -->
  <v-combobox class="input"
              color="primary"
              :label="label"
              :items="items"
              :hide-no-data="true"
              :disabled="hotkey == 'singlePress'"
              v-model="action.remapToKey"
              variant="underlined"
              @update:modelValue="changeComment(action.remapToKey)"
  ></v-combobox>
  <v-card variant="outlined" :text="errorMsg" v-if="hotkey == 'singlePress'" color="red"></v-card>
</template>

<style scoped>
.input :deep(i) {
  visibility: hidden;
}
</style>
