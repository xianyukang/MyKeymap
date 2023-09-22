<script lang="ts" setup>
import Action from "@/components/actions/Action.vue";
import Key from "@/components/Key.vue";
import { parseKeyboardLayout, useConfigStore } from "@/store/config";
import { computed } from "vue";
import ActionCommentTable from "@/components/ActionCommentTable.vue";
import trimStart from "lodash-es/trimStart";

const store = useConfigStore();

const keyboardRows = computed(() => {
  const rows = parseKeyboardLayout(store.options.keyboardLayout, store.keymap!.hotkey)
  // console.log(rows)
  return rows
})

function getKeyText(hotkey: string) {
  const string = trimStart(hotkey, '*')
  return string.charAt(0).toUpperCase() + string.slice(1)
}
</script>

<template>
  <div class="d-flex flex-wrap mt-4">
    <div class="mr-4" v-if="store.keymap" style="min-width: 500px; max-width: 1160px;">
    <v-row justify="start" v-for="(row, index) in keyboardRows" :key="index">
      <v-col v-for="(hotkey, index) in row" :key="hotkey + index" cols="auto">
        <Key :hotkey="hotkey" :label="getKeyText(hotkey)"/>
      </v-col>
    </v-row>
      <Action style="margin-top: 18px;"/>
    </div>
    <div v-else>Error: keymap not found</div>
    <action-comment-table class="ml-10 mr-4" style="min-width: 200px; flex: 1">
      <template #keyText="{ hotkey }">
        {{ getKeyText(hotkey) }}
      </template>
    </action-comment-table>
  </div>
</template>

<style scoped>
.v-row+.v-row {
  margin-top: 0;
}
</style>
