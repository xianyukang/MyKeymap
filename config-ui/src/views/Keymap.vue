<script lang="ts" setup>
import Action from "@/actions/Action.vue";
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
    ["*space", "*-", "*=", "*backspace", "*[", "*]", "*\\", "*'", "*enter"],
  ];
  if (keymap.value!.extraHotkeys) {
    const lastRow = rows[rows.length - 1];
    lastRow.push(...keymap.value!.extraHotkeys);
  }
  return rows
})



</script>

<template>
  <v-container v-if="keymap">
    <v-row justify="start" v-for="row in keyboardRows">
      <v-col v-for="hotkey in row" cols="auto">
        <Key :hotkey="hotkey" />
      </v-col>
    </v-row>
    <Action />
  </v-container>
  <div v-else>Error: keymap not found</div>
</template>

<style scoped></style>
