<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "锁屏" },
  { actionValueID: 2, label: "睡眠" },
  { actionValueID: 9, label: "睡眠(带确认)" },
  { actionValueID: 3, label: "关机" },
  { actionValueID: 4, label: "重启" },
  { actionValueID: 10, label: "重启(带确认)" },
  { actionValueID: 5, label: "音量调节" },
  { actionValueID: 6, label: "显示器亮度调节" },
]
const group2 = [
  { actionValueID: 7, label: "重启文件资源管理器" },
  { actionValueID: 8, label: "复制文件路径或纯文本" },
]
</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" />
</template>

<style scoped></style>
