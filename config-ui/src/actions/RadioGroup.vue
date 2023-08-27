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

</script>

<template>
  <v-row>
    <v-col>
      <v-radio-group density="comfortable" v-model="action.actionValueID" color="#d05">
        <v-radio v-for="item in filter(group1, keymap)"
                 :key="item.actionValueID"
                 :class="{ active: item.actionValueID == action.actionValueID }"
                 :label="item.label"
                 :value="item.actionValueID"></v-radio>
      </v-radio-group>
    </v-col>

    <v-col>
      <v-radio-group density="comfortable" v-model="action.actionValueID" color="#d05">
        <v-radio v-for="item in filter(group2, keymap)"
                 :key="item.actionValueID"
                 :class="{ active: item.actionValueID == action.actionValueID }"
                 :label="item.label"
                 :value="item.actionValueID"></v-radio>
      </v-radio-group>
    </v-col>
  </v-row>

  <v-row>
    <v-col>
      <v-radio-group density="comfortable" v-model="action.actionValueID" color="#d05">
        <v-radio v-for="item in filter(group3, keymap)"
                 :key="item.actionValueID"
                 :class="{ active: item.actionValueID == action.actionValueID }"
                 :label="item.label"
                 :value="item.actionValueID"></v-radio>
      </v-radio-group>
    </v-col>

    <v-col>
      <v-radio-group density="comfortable" v-model="action.actionValueID" color="#d05">
        <v-radio v-for="item in filter(group4, keymap)"
                 :key="item.actionValueID"
                 :class="{ active: item.actionValueID == action.actionValueID }"
                 :label="item.label"
                 :value="item.actionValueID"></v-radio>
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
