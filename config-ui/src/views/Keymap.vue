<script lang="ts" setup>

import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
const { keymap } = storeToRefs(useConfigStore())

</script>

<template>
  <div>Keymap{{ $route.params.id }}</div>
  <div>{{ keymap }}</div>
</template>

<style scoped></style>