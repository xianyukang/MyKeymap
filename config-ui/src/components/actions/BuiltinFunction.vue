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
</script>

<template>
  <v-text-field color="primary" variant="underlined" autocomplete="off" :label="label1" v-model="action.ahkCode"></v-text-field>
  <v-text-field color="primary" variant="underlined" autocomplete="off" :label="label2" v-model="action.comment"></v-text-field>
</template>

<style scoped></style>
