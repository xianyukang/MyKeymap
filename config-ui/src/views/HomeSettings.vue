<script lang="ts" setup>
import Home from "@/views/Home.vue";
import Settings from "@/views/Settings.vue";
import { useRoute } from "vue-router";
</script>

<template>
  <Home v-show="useRoute().path == '/'" />
  <Settings v-show="useRoute().path == '/settings'" />
</template>
