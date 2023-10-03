<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "关闭窗口" },
  { actionValueID: 2, label: "切换到上一个窗口" },
  { actionValueID: 3, label: "在当前程序的窗口间轮换" },
  { actionValueID: 4, label: "窗口管理 (EDSF切换X关闭、空格选择", hideInAbbr: true },
  { actionValueID: 5, label: "上一个虚拟桌面" },
  { actionValueID: 6, label: "下一个虚拟桌面" },
  { actionValueID: 7, label: "移动窗口到下一个显示器" },
  { actionValueID: 15, label: "关闭窗口 ( 杀进程 )" },
  { actionValueID: 16, label: "关闭同类窗口" },
]
const group2 = [
  { actionValueID: 8, label: "窗口最小化" },
  { actionValueID: 9, label: "窗口最大化或还原" },
  { actionValueID: 10, label: "窗口居中 (1200x800)" },
  { actionValueID: 11, label: "窗口居中 (1370x930)" },
  { actionValueID: 12, label: "切换窗口置顶状态" },
  { actionValueID: 13, label: "让窗口随鼠标拖动" },
  { actionValueID: 14, label: "绑定当前窗口 (长按绑定,短按激活", hideInAbbr: true },
]


</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" />
</template>

<style scoped></style>
