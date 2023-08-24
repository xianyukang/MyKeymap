<template>
  <v-app v-if="store.config" class="ml-4">
    <navigation-drawer />
    <default-view />
  </v-app>
</template>

<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import NavigationDrawer from './NavigationDrawer.vue';
import DefaultView from './View.vue'
const store = useConfigStore()
</script>
