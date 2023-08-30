<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { Keymap } from '@/types/config';
import { storeToRefs } from 'pinia';
import { watchEffect } from 'vue';
const { action, keymap } = storeToRefs(useConfigStore())

interface Item {
  actionValueID: number
  label: string
  hideInAbbr?: boolean
}

const props = defineProps<{
  group1: Item[]
  group2?: Item[]
  group3?: Item[]
  group4?: Item[]
}>()


function filter(group: Item[] | undefined, keymap: Keymap | undefined): Item[] | undefined {
  if (keymap?.hotkey.includes("Abbr")) {
    return group?.filter(x => !x.hideInAbbr)
  }
  return group
}

watchEffect(() => {
  action.value.isEmpty = !action.value.actionValueID
})

const groups = [[props.group1, props.group2], [props.group3, props.group4]]
</script>

<template>
  <v-row v-for="(group, index) in groups" :key="index">
    <v-col v-for="(items, index) in group" :key="index">
      <v-radio-group density="comfortable" v-model="action.actionValueID" color="#d05">
        <v-radio v-for="item in filter(items, keymap)"
                 :key="item.actionValueID"
                 :class="{ active: item.actionValueID == action.actionValueID }"
                 :label="item.label"
                 :value="item.actionValueID"
                 @click="useConfigStore().changeActionComment(item.label)"></v-radio>
      </v-radio-group>
    </v-col>
  </v-row>
</template>

<style scoped>
:deep(.v-radio-group label) {
  opacity: 1;
  color: rgba(0, 0, 0, 0.96);
}

:deep(.v-radio-group .active label) {
  color: #d05;
  font-size: 1.2em;
  transition: font-size 0.1s ease-out;
}
</style>
