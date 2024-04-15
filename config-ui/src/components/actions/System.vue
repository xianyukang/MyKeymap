<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { actionValueID: 1, label: "label:17" },
  { actionValueID: 2, label: "label:18" },
  { actionValueID: 3, label: "label:19" },
  { actionValueID: 4, label: "label:20" },
  { actionValueID: 5, label: "label:21" },
  { actionValueID: 9, label: "label:2401" },
  { actionValueID: 6, label: "label:22" },
]
const group2 = [
  { actionValueID: 7, label: "label:23" },
  { actionValueID: 8, label: "label:24" },
]
</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" />
</template>

<style scoped></style>
