<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "鼠标上移" },
  { actionValueID: 2, label: "鼠标下移" },
  { actionValueID: 3, label: "鼠标左移" },
  { actionValueID: 4, label: "鼠标右移" },
]
const group2 = [
  { actionValueID: 5, label: "滚轮上滑" },
  { actionValueID: 6, label: "滚轮下滑" },
  { actionValueID: 7, label: "滚轮左滑" },
  { actionValueID: 8, label: "滚轮右滑" },
]
const group3 = [
  { actionValueID: 9, label: "鼠标左键" },
  { actionValueID: 10, label: "鼠标右键" },
  { actionValueID: 11, label: "鼠标中键" },
  { actionValueID: 12, label: "鼠标左键按下 (之后按空格松开)" },
]


</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" :group3="group3" />
</template>

<style scoped></style>
