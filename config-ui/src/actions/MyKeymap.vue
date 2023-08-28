<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "暂停 MyKeymap" },
  { actionValueID: 2, label: "重启 MyKeymap" },
  { actionValueID: 3, label: "退出 MyKeymap" },
  { actionValueID: 4, label: "打开 MyKeymap 设置" },
]
const group2 = [
  { actionValueID: 5, label: "触发 缩写功能" },
  { actionValueID: 6, label: "触发 Capslock 命令" },
  { actionValueID: 7, label: "切换 Capslock 大小写" },
  { actionValueID: 8, label: "锁定当前模式 (免去按住触发键)" },
]
</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" />
</template>

<style scoped></style>
