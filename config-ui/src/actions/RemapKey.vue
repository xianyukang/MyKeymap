<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
const { action } = storeToRefs(useConfigStore())
const label = "重映射为"
const items = [
  'up', 'down', 'left', 'right', 'home', 'end', 'backspace', 'delete',
  'space', 'tab', 'enter', 'esc', 'insert', 'capslock', 'appskey', 'pgup', 'pgdn',
  'LWin', 'RWin', 'LCtrl', 'RCtrl', 'LAlt', 'RAlt', 'LShift', 'RShift', 'PrintScreen',
  'volume_mute', 'volume_up', 'volume_down', 'media_next', 'media_prev', 'media_stop', 'media_play_pause',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'f10', 'f11', 'f12',
]

</script>

<template>
  <!-- :menu-props="{ maxHeight: '390px' }" 可以调整下拉框高度 -->
  <v-autocomplete class="input"
                  :label="label"
                  :items="items"
                  :hide-no-data="true"
                  v-model="action.remapToKey"
                  variant="underlined"></v-autocomplete>
</template>

<style scoped>
.input :deep(i) {
  visibility: hidden;
}
</style>
