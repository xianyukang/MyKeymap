<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';


const { action } = storeToRefs(useConfigStore())

</script>

<template>
  <div>{{ action }}</div>
</template>

<style scoped></style>
