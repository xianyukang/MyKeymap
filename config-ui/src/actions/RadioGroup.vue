<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import { watchEffect } from 'vue';
const { action } = storeToRefs(useConfigStore())

const props = defineProps<{
  group1: { actionValueID: number, label: string }[]
  group2?: { actionValueID: number, label: string }[]
  group3?: { actionValueID: number, label: string }[]
  group4?: { actionValueID: number, label: string }[]
}>()


watchEffect(() => {
  action.value.isEmpty = !action.value.actionValueID
})

</script>

<template>
  <v-row>
    <v-col>
      <v-radio-group density="comfortable" v-model="action.actionValueID" color="#d05">
        <v-radio v-for="item in group1"
                 :key="item.actionValueID"
                 :class="{ active: item.actionValueID == action.actionValueID }"
                 :label="item.label"
                 :value="item.actionValueID"></v-radio>
      </v-radio-group>
    </v-col>

    <v-col>
      <v-radio-group density="comfortable" v-model="action.actionValueID" color="#d05">
        <v-radio v-for="item in group2"
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
        <v-radio v-for="item in group3"
                 :key="item.actionValueID"
                 :class="{ active: item.actionValueID == action.actionValueID }"
                 :label="item.label"
                 :value="item.actionValueID"></v-radio>
      </v-radio-group>
    </v-col>

    <v-col>
      <v-radio-group density="comfortable" v-model="action.actionValueID" color="#d05">
        <v-radio v-for="item in group4"
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
