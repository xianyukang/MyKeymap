<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';


const { config, action, windowGroupID, hotkey } = storeToRefs(useConfigStore())

const actionTypes = [
  { id: 0, name: "⛔ 未配置" },
  { id: 1, name: "👾 启动程序或激活窗口" },
  { id: 2, name: "🖥️ 系统控制" },
  { id: 3, name: "🏠 窗口操作" },
  { id: 4, name: "🖱️  鼠标操作" },
  { id: 5, name: "🅰️ 重映射按键" },
  { id: 6, name: "🅰️ 输入文本或按键" },
  { id: 7, name: "📚 一些文字处理" },
  { id: 8, name: "⚛️ 一些内置函数" },
  { id: 9, name: "⚙️ MyKeymap 相关" },
]

function onWindowGroupIDChange() {

}

function onActionTypeChange() {

}



</script>

<template>
  <v-row>
    <v-col>
      <v-card min-height="550" width="930" elevation="5" class="action-config">
        <v-card-title style="padding-bottom: 0">
          <v-row>
            <v-col cols="5">
              <v-select :items="config!.options.windowGroups"
                        item-title="name"
                        item-value="id"
                        v-model="windowGroupID"
                        @change="onWindowGroupIDChange"
                        variant="outlined"
                        :menu-props="{ maxHeight: 900 }"
                        :disabled="!hotkey"></v-select>
            </v-col>
            <v-col cols="7">
              <v-select :items="actionTypes"
                        item-title="name"
                        item-value="id"
                        v-model="action.actionTypeID"
                        @change="onActionTypeChange"
                        variant="outlined"
                        :menu-props="{ maxHeight: 900 }"
                        :disabled="!hotkey"></v-select>
            </v-col>
          </v-row>
        </v-card-title>
      </v-card>
    </v-col>
  </v-row>
</template>

<style scoped></style>
