<script setup lang="ts">

import InputKeyValueDialog from "@/components/dialog/InputKeyValueDialog.vue";

import { useConfigStore } from "@/store/config";
import { storeToRefs } from "pinia";
import { server } from "@/store/server";
import { WindowGroup } from "@/types/config";
import { computed } from "@vue/reactivity";

const { options } = storeToRefs(useConfigStore())
const { translate } = useConfigStore()
const windowGroupConditionTypes = computed(() => {
  return [
    { name: translate('label:605'), index: 1 },
    { name: translate('label:606'), index: 2 },
    { name: translate('label:607'), index: 3 },
    { name: translate('label:608'), index: 4 }
  ]
})

const addItem = (dataObj: WindowGroup[]) => {
  dataObj.push({ id: dataObj.length + 1, name: "", value: "", conditionType: 1 })
}

const save = (dataObj: WindowGroup[]) => {
  options.value.windowGroups = dataObj
}

</script>

<template>
  <input-key-value-dialog title="" :data-obj="options.windowGroups"
                          @add="addItem" @save="save">
    <template #default="{ props }">
      <v-btn class="mt-3 text-none" width="170" color="blue" v-bind="props" variant="outlined">{{ translate('label:601') }}</v-btn>
    </template>

    <template #tips>{{ translate('label:612') }}</template>

    <template #contentsTitle>
      <v-col cols="3">{{ translate('label:602') }}</v-col>
      <v-col cols="6">{{ translate('label:603') }}</v-col>
      <v-col cols="3">{{ translate('label:604') }}</v-col>
    </template>
    <template #contents="{ data }">
      <v-col cols="3">
        <v-text-field v-model="data.name" variant="outlined"
                      :dense="true" :disabled="data.id <= 0"></v-text-field>
      </v-col>
      <v-col cols="6">
        <v-textarea v-model="data.value" auto-grow rows="1"
                    variant="outlined" :disabled="data.id == 0"></v-textarea>
      </v-col>
      <v-col cols="3">
        <v-select v-model="data.conditionType" :items="windowGroupConditionTypes"
                  :item-title="item => item.name" :item-value="item => item.index"
                  :disabled="data.id <= 0" variant="outlined">
        </v-select>
      </v-col>
    </template>
    <template #otherActions>
      <!-- <v-label style="color: green;">Tip: 使用程序组，可设置热键的生效条件 &nbsp;</v-label> -->
      <v-btn class="action-button text-none" color="primary" variant="outlined" @click="server.runWindowSpy">{{ translate('label:309') }}</v-btn>
    </template>
  </input-key-value-dialog>
</template>

<style scoped></style>
