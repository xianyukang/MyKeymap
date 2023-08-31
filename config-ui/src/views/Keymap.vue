<script lang="ts" setup>
import Action from "@/components/actions/Action.vue";
import Key from "@/components/Key.vue";
import { useConfigStore } from "@/store/config";
import { storeToRefs } from "pinia";
import { computed } from "vue";
const { keymap } = storeToRefs(useConfigStore());


const keyboardRows = computed(() => {
  const rows = [
    ["*1", "*2", "*3", "*4", "*5", "*6", "*7", "*8", "*9", "*0"],
    ["*q", "*w", "*e", "*r", "*t", "*y", "*u", "*i", "*o", "*p"],
    ["*a", "*s", "*d", "*f", "*g", "*h", "*j", "*k", "*l", "*;"],
    ["*z", "*x", "*c", "*v", "*b", "*n", "*m", "*,", "*.", "*/"],
    ["*space", "*enter", "*backspace", "*-", "*[", "*'", "singlePress"],
  ];
  if (keymap.value?.hotkey.toLowerCase().includes("rbutton")) {
    rows[rows.length-1].push("*LButton", "*WheelUp", "*WheelDown")
  }
  return rows
})



</script>

<template>
  <v-container v-if="keymap">
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
