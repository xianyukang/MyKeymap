<script setup lang="ts">

import InputKeyValueDialog from "@/components/dialog/InputKeyValueDialog.vue";

import { useConfigStore } from "@/store/config";
import { storeToRefs } from "pinia";
import { server } from "@/store/server";
import { WindowGroup } from "@/types/config";

const { options } = storeToRefs(useConfigStore())
const windowGroupConditionTypes: { name: string; index: number }[] = [
  { name: "条件: 是前台窗口", index: 1 },
  { name: "条件: 这些窗口存在", index: 2 },
  { name: "条件: 不是前台窗口", index: 3 },
  { name: "条件: 这些窗口不存在", index: 4 }
]

const addItem = (dataObj: WindowGroup[]) => {
  dataObj.push({ id: dataObj.length + 1, name: "", value: "", conditionType: 1 })
}

const save = (dataObj: WindowGroup[]) => {
  options.value.windowGroups = dataObj
}

</script>

<template>
  <input-key-value-dialog title="编辑程序组" key-title-label="组名"
                          value-title-label="窗口标识符"
                          :data-obj="options.windowGroups"
                          @add="addItem" @save="save">
    <template #default="{ props }">
      <v-btn class="mt-5" width="170" color="blue" v-bind="props" variant="outlined">编辑程序组</v-btn>
    </template>

    <template #contents="{ data }">
      <v-col cols="3">
        <v-text-field v-model="data.name" variant="outlined"
                      :dense="true" :disabled="data.id == 0"></v-text-field>
      </v-col>
      <v-col>
        <v-textarea v-model="data.value" auto-grow rows="1"
                    variant="outlined" :disabled="data.id == 0"></v-textarea>
      </v-col>

      <v-col sm="2">
        <v-select v-model="data.conditionType" :items="windowGroupConditionTypes"
                  :item-title="item => item.name" :item-value="item => item.index"
                  :disabled="data.id == 0" variant="outlined" style="width: 14rem">
        </v-select>
      </v-col>
    </template>
    <template #otherActions>
      <v-btn class="action-button" color="primary" variant="outlined"
             @click="server.runWindowSpy">🔍 查看窗口标识符
      </v-btn>
    </template>
  </input-key-value-dialog>
</template>

<style scoped></style>
