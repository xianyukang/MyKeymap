<script setup lang="ts">

import Code from "@/components/Code.vue";
import InputKeyValueDialog from "@/components/dialog/InputKeyValueDialog.vue";

import { useConfigStore } from "@/store/config";
import { storeToRefs } from "pinia";
import { PathVariable } from "@/types/config";

const { options } = storeToRefs(useConfigStore())

const addItem = (dataObj: PathVariable[]) => {
  dataObj.push({ name: "", value: "" })
  options.value.pathVariables = dataObj
}

const save = (dataObj: PathVariable[]) => {
  options.value.pathVariables = dataObj
}

</script>

<template>
  <input-key-value-dialog title="编辑路径变量" key-title-label="变量名"
                          value-title-label="变量值" :data-obj="options.pathVariables"
                          @add="addItem" @save="save">
    <template #tips>
      <p>先定义一个 <Code>programs</Code> 变量，值为 <Code>C:\ProgramData\Microsoft\Windows\Start Menu\Programs\</Code>，然后就能在「 程序路径 」中<br></p>
      <p>使用 <Code>ahk-expression: programs "Microsoft Edge.lnk"</Code> 表示 <Code>C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk</Code></p>
    </template>
    <template #default="{props}">
      <v-btn class="mt-5" width="170" color="blue" v-bind="props" variant="outlined">
        编辑路径变量
      </v-btn>
    </template>

    <template #contents="{data}">
      <v-col cols="3">
        <v-text-field v-model="data.name" variant="outlined"
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
p {
  margin-top: 8px;
  margin-bottom: 8px;
}
</style>
