<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "label:1" },
  { actionValueID: 2, label: "label:2" },
  { actionValueID: 3, label: "label:3" },
  { actionValueID: 4, label: "label:4", hideInAbbr: true },
  { actionValueID: 5, label: "label:5" },
  { actionValueID: 6, label: "label:6" },
  { actionValueID: 7, label: "label:7" },
  { actionValueID: 15, label: "label:8" },
  { actionValueID: 16, label: "label:9" },
]
const group2 = [
  { actionValueID: 8, label: "label:10" },
  { actionValueID: 9, label: "label:11" },
  { actionValueID: 10, label: "label:12" },
  { actionValueID: 11, label: "label:13" },
  { actionValueID: 12, label: "label:14" },
  { actionValueID: 13, label: "label:15" },
  { actionValueID: 14, label: "label:16", hideInAbbr: true },
]


</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" />
</template>

<style scoped></style>
