<script setup lang="ts">

import InputKeyValueDialog from "@/components/dialog/InputKeyValueDialog.vue";

import { useConfigStore } from "@/store/config";
import { storeToRefs } from "pinia";
import { server } from "@/store/server";
import { WindowGroup } from "@/types/config";

const { options } = storeToRefs(useConfigStore())
const windowGroupConditionTypes: { name: string; index: number }[] = [
  { name: "是前台窗口", index: 1 },
  { name: "这些窗口存在", index: 2 },
  { name: "不是前台窗口", index: 3 },
  { name: "这些窗口不存在", index: 4 }
]

const addItem = (dataObj: WindowGroup[]) => {
  dataObj.push({ id: dataObj.length + 1, name: "", value: "", conditionType: 1 })
}

const save = (dataObj: WindowGroup[]) => {
  options.value.windowGroups = dataObj
}

</script>

<template>
  <input-key-value-dialog title="编辑程序组" :data-obj="options.windowGroups"
                          @add="addItem" @save="save">
    <template #default="{ props }">
      <v-btn class="mt-3" width="170" color="blue" v-bind="props" variant="outlined">编辑程序组</v-btn>
    </template>

    <template #contentsTitle>
      <v-col cols="3">组名</v-col>
      <v-col cols="6">窗口标识符</v-col>
      <v-col cols="3">条件</v-col>
    </template>
    <template #contents="{ data }">
      <v-col cols="3">
        <v-text-field v-model="data.name" variant="outlined"
                      :dense="true" :disabled="data.id == 0"></v-text-field>
      </v-col>
      <v-col cols="6">
        <v-textarea v-model="data.value" auto-grow rows="1"
                    variant="outlined" :disabled="data.id == 0"></v-textarea>
      </v-col>
      <v-col cols="3">
        <v-select v-model="data.conditionType" :items="windowGroupConditionTypes"
                  :item-title="item => item.name" :item-value="item => item.index"
                  :disabled="data.id == 0" variant="outlined">
        </v-select>
      </v-col>
    </template>
    <template #otherActions>
      <v-label style="color: green;">Tip: 使用程序组，可设置热键的生效条件 &nbsp;</v-label>
      <v-btn class="action-button" color="primary" variant="outlined"
             @click="server.runWindowSpy">🔍 查看窗口标识符
      </v-btn>
    </template>
  </input-key-value-dialog>
</template>

<style scoped></style>
