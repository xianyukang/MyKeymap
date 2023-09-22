<script setup lang="ts">

import Table from "@/components/Table.vue";
import { Action as IAction } from "@/types/config";
import trimEnd from "lodash-es/trimEnd";
import { useConfigStore } from "@/store/config";

const store = useConfigStore();
const getActionAllComment = (actions: IAction[]) => {
  let comment = actions.reduce((pre, current) => {
    if (current.comment) {
      let groupName = current.windowGroupID == 0 ? "" : store.options.windowGroups.find(w => w.id == current.windowGroupID)?.name + ": "
      return pre + groupName + current.comment + "\r\n"
    }
    return pre
  }, "")

  return trimEnd(comment, "\n")
}

const showActionComment = (actions: IAction[]) => {
  for (let action of actions) {
    if (!action.isEmpty) {
      return true
    }
  }
}

</script>

<template>
  <v-card>
    <Table class="text-left" :titles="['热键', '备注']">
      <tr v-for="(action, hotkey, index) in store.hotkeys" :key="index">
        <td v-if="showActionComment(action)">
          <slot name="keyText" :hotkey="hotkey"></slot>
        </td>
        <td v-if="showActionComment(action)" class="text-pre overflow-hidden">
          {{ getActionAllComment(action) }}
        </td>
      </tr>
    </Table>
  </v-card>
</template>

<style scoped>

td {
  height: 2.3rem;
}

</style>
