<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import { watchEffect } from 'vue';
const { action } = storeToRefs(useConfigStore())
const { translate } = useConfigStore()

watchEffect(() => {
  action.value.isEmpty = !action.value.keysToSend
})
</script>

<template>
  <v-textarea color="primary" variant="underlined" auto-grow rows="1" :label="translate('label:402')" v-model="action.keysToSend"></v-textarea>
  <v-text-field color="primary" variant="underlined" autocomplete="off" :label="translate('label:305')" v-model="action.comment"></v-text-field>
</template>

<style scoped></style>
