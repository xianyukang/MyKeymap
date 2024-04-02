<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "label:25" },
  { actionValueID: 2, label: "label:26" },
  { actionValueID: 3, label: "label:27" },
  { actionValueID: 4, label: "label:28" },
]
const group2 = [
  { actionValueID: 5, label: "label:29" },
  { actionValueID: 6, label: "label:30" },
  { actionValueID: 7, label: "label:31" },
  { actionValueID: 8, label: "label:32" },
]
const group3 = [
  { actionValueID: 9, label:  "label:33" },
  { actionValueID: 10, label: "label:34" },
  { actionValueID: 11, label: "label:35" },
  { actionValueID: 12, label: "label:36" },
]
const group4 = [
  { actionValueID: 13, label: "label:37" },
]


</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" :group3="group3" :group4="group4" />
</template>

<style scoped></style>
