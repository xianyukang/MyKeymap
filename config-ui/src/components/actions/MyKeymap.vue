<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "label:71", hideInAbbr: true },
  { actionValueID: 2, label: "label:72" },
  { actionValueID: 3, label: "label:73" },
  { actionValueID: 4, label: "label:74" },
]
const group2 = [
  { actionValueID: 5, label: "label:75", hideInAbbr: true },
  { actionValueID: 6, label: "label:76", hideInAbbr: true },
  { actionValueID: 7, label: "label:77" },
  { actionValueID: 8, label: "label:78", hideInAbbr: true },
]
</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" />
</template>

<style scoped></style>
