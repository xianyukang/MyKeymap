<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import { watchEffect } from 'vue';
const { action } = storeToRefs(useConfigStore())
const label1 = "要输入的按键或文本"
const label2 = "自定义备注"

watchEffect(() => {
  action.value.isEmpty = !action.value.keysToSend
})
</script>

<template>
  <v-textarea color="primary" variant="underlined" auto-grow rows="1" :label="label1" v-model="action.keysToSend"></v-textarea>
  <v-text-field color="primary" variant="underlined" autocomplete="off" :label="label2" v-model="action.comment"></v-text-field>
</template>

<style scoped></style>
