<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { hideInAbbr: true, actionValueID: 1, label: "光标 - 上移" },
  { hideInAbbr: true, actionValueID: 2, label: "光标 - 下移" },
  { hideInAbbr: true, actionValueID: 3, label: "光标 - 左移" },
  { hideInAbbr: true, actionValueID: 4, label: "光标 - 右移" },
  { hideInAbbr: true, actionValueID: 5, label: "光标 - 跳到行首" },
  { hideInAbbr: true, actionValueID: 6, label: "光标 - 跳到行尾" },
  { hideInAbbr: true, actionValueID: 7, label: "光标 - 上一单词" },
  { hideInAbbr: true, actionValueID: 8, label: "光标 - 下一单词" },
]
const group2 = [
  { hideInAbbr: true, actionValueID: 9, label: "选择 - 往上" },
  { hideInAbbr: true, actionValueID: 10, label: "选择 - 往下" },
  { hideInAbbr: true, actionValueID: 11, label: "选择 - 往左" },
  { hideInAbbr: true, actionValueID: 12, label: "选择 - 往右" },
  { hideInAbbr: true, actionValueID: 13, label: "选择 - 选到行首" },
  { hideInAbbr: true, actionValueID: 14, label: "选择 - 选到行尾" },
  { hideInAbbr: true, actionValueID: 15, label: "选择 - 上一单词" },
  { hideInAbbr: true, actionValueID: 16, label: "选择 - 下一单词" },
]

const group3 = [
  { hideInAbbr: true, actionValueID: 17, label: "右键菜单" },
  { hideInAbbr: true, actionValueID: 33, label: "删除一行文本" },
  { hideInAbbr: true, actionValueID: 18, label: "删除一个单词" },
  { hideInAbbr: true, actionValueID: 19, label: "Shift 键" },
  { hideInAbbr: true, actionValueID: 30, label: "Ctrl 键" },
  { hideInAbbr: true, actionValueID: 31, label: "Alt 键" },
  { hideInAbbr: true, actionValueID: 32, label: "Win 键" },
  { hideInAbbr: false, actionValueID: 29, label: "中英文之间加空格" },
]

const group4 = [
  { hideInAbbr: true, actionValueID: 20, label: "Esc" },
  { hideInAbbr: true, actionValueID: 21, label: "Backspace" },
  { hideInAbbr: true, actionValueID: 22, label: "Enter" },
  { hideInAbbr: true, actionValueID: 23, label: "Delete" },
  { hideInAbbr: true, actionValueID: 24, label: "Insert" },
  { hideInAbbr: true, actionValueID: 25, label: "Tab" },
  { hideInAbbr: true, actionValueID: 26, label: "Ctrl + Tab" },
  { hideInAbbr: true, actionValueID: 27, label: "Shift + Tab" },
  { hideInAbbr: true, actionValueID: 28, label: "Ctrl+Shift+Tab" },
]


</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" :group3="group3" :group4="group4" horizontal />
</template>

<style scoped></style>
