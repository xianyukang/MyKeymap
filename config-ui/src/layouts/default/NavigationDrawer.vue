<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
const { config } = storeToRefs(useConfigStore())

</script>

<template>
  <v-navigation-drawer>
    <v-list>
      <v-list-item v-for="km in config.keymaps" :title="km.name"></v-list-item>
    </v-list>
  </v-navigation-drawer>
</template>

