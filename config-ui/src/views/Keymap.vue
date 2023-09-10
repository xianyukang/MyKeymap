<script lang="ts" setup>
import Action from "@/components/actions/Action.vue";
import Key from "@/components/Key.vue";
import { parseKeyboardLayout, useConfigStore } from "@/store/config";
import { computed } from "vue";
const store = useConfigStore();

const keyboardRows = computed(() => {
  const rows = parseKeyboardLayout(store.options.keyboardLayout, store.keymap!.hotkey)
  // console.log(rows)
  return rows
})



</script>

<template>
  <v-container v-if="store.keymap">
    <v-row justify="start" v-for="(row, index) in keyboardRows" :key="index">
      <v-col v-for="(hotkey, index) in row" :key="hotkey + index" cols="auto">
        <Key :hotkey="hotkey" />
      </v-col>
    </v-row>
    <Action style="margin-top: 18px;" />
  </v-container>
  <div v-else>Error: keymap not found</div>
</template>

<style scoped>
.v-row+.v-row {
  margin-top: 0;
}
</style>
