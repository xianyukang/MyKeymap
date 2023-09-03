<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "光标 - 上移" },
  { actionValueID: 2, label: "光标 - 下移" },
  { actionValueID: 3, label: "光标 - 左移" },
  { actionValueID: 4, label: "光标 - 右移" },
  { actionValueID: 5, label: "光标 - 跳到行首" },
  { actionValueID: 6, label: "光标 - 跳到行尾" },
  { actionValueID: 7, label: "光标 - 上一单词" },
  { actionValueID: 8, label: "光标 - 下一单词" },
]
const group2 = [
  { actionValueID: 9, label: "选择 - 往上" },
  { actionValueID: 10, label: "选择 - 往下" },
  { actionValueID: 11, label: "选择 - 往左" },
  { actionValueID: 12, label: "选择 - 往右" },
  { actionValueID: 13, label: "选择 - 选到行首" },
  { actionValueID: 14, label: "选择 - 选到行尾" },
  { actionValueID: 15, label: "选择 - 上一单词" },
  { actionValueID: 16, label: "选择 - 下一单词" },
]

const group3 = [
  { actionValueID: 17, label: "右键菜单" },
  { actionValueID: 18, label: "删除一个单词" },
  { actionValueID: 19, label: "Shift 键" },
]
const group4 = [
  { actionValueID: 20, label: "Esc" },
  { actionValueID: 21, label: "Backspace" },
  { actionValueID: 22, label: "Enter" },
  { actionValueID: 23, label: "Delete" },
  { actionValueID: 24, label: "Insert" },
  { actionValueID: 25, label: "Tab" },
  { actionValueID: 26, label: "Ctrl + Tab" },
  { actionValueID: 27, label: "Shift + Tab" },
  { actionValueID: 28, label: "Ctrl+Shift+Tab" },
]


</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" :group3="group3" :group4="group4" horizontal />
</template>

<style scoped></style>
