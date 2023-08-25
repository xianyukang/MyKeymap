<script setup lang="ts">

const props = defineProps<{ text: string }>()

</script>

<template>
  <v-tooltip :text="props.text">
    <template #activator="{props}">
      <div v-bind="props">
        <slot></slot>
      </div>
    </template>
  </v-tooltip>
</template>

<style scoped>

</style>
