<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import { watchEffect } from 'vue';

const { action } = storeToRefs(useConfigStore())
const label1 = "代码"
const label2 = "自定义备注"

watchEffect(() => {
  action.value.isEmpty = !action.value.ahkCode
})

const items = [
  `CenterAndResizeWindow(1600, 1000)`,
  `ProcessExistSendKeyOrRun("WeChat.exe", "^!w", "shortcuts\\微信.lnk")`,
]
</script>

<template>
  <v-combobox class="input" color="primary" :label="label1" :items="items" hide-no-data v-model="action.ahkCode" variant="underlined" />
  <v-text-field color="primary" variant="underlined" autocomplete="off" :label="label2" v-model="action.comment"></v-text-field>
  <br>
  <br>
  <p>Tips:</p>
  <p>(1) 自定义函数可放到 data\custom_functions.ahk，然后在此处调用</p>
  <p>(2) 复杂的脚本推荐做成独立的 ahk 文件，然后用 MyKeymap 启动那个 ahk 文件</p>
</template>

<style scoped>
.input :deep(i) {
  visibility: hidden;
}
</style>
