<script setup lang="ts">

const props = defineProps<{ text: string }>()

</script>

<template>
  <v-tooltip :text="props.text" v-if="text">
    <template #activator="{ props }">
      <div v-bind="props">
        <slot></slot>
      </div>
    </template>
  </v-tooltip>
  <template v-else>
    <div v-bind="props">
      <slot></slot>
    </div>
  </template>
</template>

<style scoped>

</style>
