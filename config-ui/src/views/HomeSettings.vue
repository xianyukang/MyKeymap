<script lang="ts" setup>
import Home from './Home.vue';
import Settings from './Settings.vue';
</script>

<template>
  <Home v-show="$route.path != '/settings'" />
  <Settings v-show="$route.path == '/settings'" />
</template>
