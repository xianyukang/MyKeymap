<script setup lang="ts">

import Code from "@/components/Code.vue";
import InputKeyValueDialog from "@/components/dialog/InputKeyValueDialog.vue";

import { useConfigStore } from "@/store/config";
import { storeToRefs } from "pinia";
import { Path } from "@/types/config";

const { options } = storeToRefs(useConfigStore())

const addItem = (dataObj: Path[]) => {
  dataObj.push({ key: "", value: "" })
}

const save = (dataObj: Path[]) => {
  options.value.path = dataObj
}

</script>

<template>
  <input-key-value-dialog title="编辑环境变量" key-title-label="变量名"
                          value-title-label="变量值" :data-obj="options.path"
                          @add="addItem" @save="save">
    <template #tips>
      使用路径变量能缩短路径长度, 比如 <Code>%Home%\Documents</Code> 表示
      <Code>C:\Users\YourUserName\Documents</Code>
    </template>
    <template #default="{props}">
      <v-btn class="mt-5" width="170" color="blue" v-bind="props">
        编辑路径变量
      </v-btn>
    </template>

    <template #contents="{data}">
      <v-col cols="2">
        <v-text-field v-model="data.key" variant="outlined"
                      :dense="true"></v-text-field>
      </v-col>
      <v-col>
        <v-text-field v-model="data.value" auto-grow rows="1"
                      variant="outlined"></v-text-field>
      </v-col>
    </template>
  </input-key-value-dialog>
</template>

<style scoped>

</style>
