<script lang="ts" setup>
import RadioGroup from './RadioGroup.vue';

const group1 = [
  { hideInAbbr: true, actionValueID: 1, label: "label:38" },
  { hideInAbbr: true, actionValueID: 2, label: "label:39" },
  { hideInAbbr: true, actionValueID: 3, label: "label:40" },
  { hideInAbbr: true, actionValueID: 4, label: "label:41" },
  { hideInAbbr: true, actionValueID: 5, label: "label:42" },
  { hideInAbbr: true, actionValueID: 6, label: "label:43" },
  { hideInAbbr: true, actionValueID: 7, label: "label:44" },
  { hideInAbbr: true, actionValueID: 8, label: "label:45" },
]
const group2 = [
  { hideInAbbr: true, actionValueID: 9, label: "label:46" },
  { hideInAbbr: true, actionValueID: 10, label: "label:47" },
  { hideInAbbr: true, actionValueID: 11, label: "label:48" },
  { hideInAbbr: true, actionValueID: 12, label: "label:49" },
  { hideInAbbr: true, actionValueID: 13, label: "label:50" },
  { hideInAbbr: true, actionValueID: 14, label: "label:51" },
  { hideInAbbr: true, actionValueID: 15, label: "label:52" },
  { hideInAbbr: true, actionValueID: 16, label: "label:53" },
]

const group3 = [
  { hideInAbbr: true, actionValueID: 17, label: "label:54" },
  { hideInAbbr: true, actionValueID: 33, label: "label:55" },
  { hideInAbbr: true, actionValueID: 18, label: "label:56" },
  { hideInAbbr: true, actionValueID: 19, label: "label:57" },
  { hideInAbbr: true, actionValueID: 30, label: "label:58" },
  { hideInAbbr: true, actionValueID: 31, label: "label:59" },
  { hideInAbbr: true, actionValueID: 32, label: "label:60" },
  { hideInAbbr: false, actionValueID: 29, label: "label:61" },
]

const group4 = [
  { hideInAbbr: true, actionValueID: 20, label: "label:62" },
  { hideInAbbr: true, actionValueID: 21, label: "label:63" },
  { hideInAbbr: true, actionValueID: 22, label: "label:64" },
  { hideInAbbr: true, actionValueID: 23, label: "label:65" },
  { hideInAbbr: true, actionValueID: 24, label: "label:66" },
  { hideInAbbr: true, actionValueID: 25, label: "label:67" },
  { hideInAbbr: true, actionValueID: 26, label: "label:68" },
  { hideInAbbr: true, actionValueID: 27, label: "label:69" },
  { hideInAbbr: true, actionValueID: 28, label: "label:70" },
]


</script>

<template>
  <RadioGroup :group1="group1" :group2="group2" :group3="group3" :group4="group4" horizontal />
</template>

<style scoped></style>
