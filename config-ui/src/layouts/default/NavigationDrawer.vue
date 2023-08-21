<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
const { enabledKeymaps } = storeToRefs(useConfigStore())

</script>

<template>
  <v-navigation-drawer>
    <v-list nav>
      <v-list-item v-for="km in enabledKeymaps" :title="km.name" :to="'/keymap/' + km.id"></v-list-item>
    </v-list>
  </v-navigation-drawer>
</template>

