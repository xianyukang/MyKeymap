<script lang="ts" setup>

import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
const { keymap, action } = storeToRefs(useConfigStore())

</script>

<template>
  <div>Keymap{{ $route.params.id }}</div>
  <div>{{ keymap }}</div>
  <div>{{ action }}</div>
</template>

<style scoped></style>