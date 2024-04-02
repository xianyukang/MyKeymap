<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import { watchEffect } from 'vue';
const { action, hotkey } = storeToRefs(useConfigStore())
const { translate } = useConfigStore()
const items = [
  'Up', 'Down', 'Left', 'Right', 'Home', 'End', 'Backspace', 'Delete',
  'Space', 'Tab', 'Enter', 'Escape', 'Insert', 'CapsLock', 'AppsKey', 'PgUp', 'PgDn',
  'LWin', 'RWin', 'LControl', 'RControl', 'LAlt', 'RAlt', 'LShift', 'RShift', 'PrintScreen',
  'Volume_Mute', 'Volume_Up', 'Volume_Down', 'Media_Next', 'Media_Prev', 'Media_Stop', 'Media_Play_Pause',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  'F1', 'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'F9', 'F10', 'F11', 'F12',
]

const errorMsg = "当前键不支持「 重映射 」，请使用「 输入文本或按键 」"

watchEffect(() => {
  action.value.isEmpty = !action.value.remapToKey
})

const changeComment = (key?: string) => {
  useConfigStore().changeActionComment(key ? translate('label:401') + " " + key : "")
}

</script>

<template>
  <!-- :menu-props="{ maxHeight: '390px' }" 可以调整下拉框高度 -->
  <v-combobox class="input"
              color="primary"
              :label="translate('label:401')"
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
