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
import { onMounted } from "vue";
const store = useConfigStore()

onMounted(() => {
  window.addEventListener("keydown", evt => {
    if (evt.ctrlKey && evt.key.toLowerCase() === 's') {
      evt.preventDefault()
      store.saveConfig()
    }
  })
})

</script>
