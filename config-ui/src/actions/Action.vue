<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import ActivateOrRun from '@/actions/ActivateOrRun.vue'
import System from '@/actions/System.vue'
import Window from '@/actions/Window.vue'
import Mouse from '@/actions/Mouse.vue'
import RemapKey from '@/actions/RemapKey.vue'
import SendKey from '@/actions/SendKey.vue'
import Text from '@/actions/Text.vue'
import BuiltinFunction from '@/actions/BuiltinFunction.vue'
import MyKeymap from '@/actions/MyKeymap.vue'
import { Action, Keymap } from "@/types/config";


const { config, keymap, action, windowGroupID, hotkey } = storeToRefs(useConfigStore())

const actionTypes = [
  { id: 0, name: "⛔ 未配置" },
  { id: 1, name: "👾 启动程序或激活窗口" },
  { id: 2, name: "🖥️ 系统控制" },
  { id: 3, name: "🏠 窗口操作" },
  { id: 4, name: "🖱️  鼠标操作", hideInAbbr: true },
  { id: 5, name: "🅰️ 重映射按键", hideInAbbr: true },
  { id: 6, name: "🅰️ 输入文本或按键" },
  { id: 7, name: "📚 一些文字处理" },
  { id: 8, name: "⚛️ 一些内置函数" },
  { id: 9, name: "⚙️ MyKeymap 相关" },
]

function filter(items: typeof actionTypes, keymap: Keymap | undefined): typeof actionTypes {
  if (keymap && keymap.hotkey.includes("Abbr")) {
    return items.filter(x => !x.hideInAbbr)
  }
  return items
}

const components: any = {
  1: ActivateOrRun,
  2: System,
  3: Window,
  4: Mouse,
  5: RemapKey,
  6: SendKey,
  7: Text,
  8: BuiltinFunction,
  9: MyKeymap,
}


function onActionTypeChange(action: Action) {
  // 删掉除 windowGroupID 和 actionTypeID 之外的字段
  for (const key of Object.keys(action)) {
    if (key === "windowGroupID" || key === "actionTypeID") {
      // skip
    } else {
      delete action[key as keyof Action];
    }
  }
  if (action.actionTypeID === 0) {
    action.isEmpty = true
  }
}



</script>

<template>
  <v-row>
    <v-col>
      <v-card min-height="550" width="800" elevation="5">
        <v-card-title style="padding-bottom: 0">
          <v-row>
            <v-col cols="5">
              <v-select :items="config!.options.windowGroups"
                        item-title="name"
                        item-value="id"
                        v-model="windowGroupID"
                        variant="outlined"
                        :menu-props="{ maxHeight: 900 }"
                        :disabled="!hotkey"></v-select>
            </v-col>
            <v-col cols="7">
              <v-select :items="filter(actionTypes, keymap)"
                        item-title="name"
                        item-value="id"
                        v-model="action.actionTypeID"
                        @update:model-value="onActionTypeChange(action)"
                        variant="outlined"
                        :menu-props="{ maxHeight: 900 }"
                        :disabled="!hotkey"></v-select>
            </v-col>
          </v-row>
        </v-card-title>
        <v-card-text>
          <component :is="components[action.actionTypeID]" />
        </v-card-text>
      </v-card>
    </v-col>
  </v-row>
</template>

<style scoped>
.v-card {
  padding-top: 8px;
  padding-left: 10px;
  padding-right: 10px;
}

/* 默认的 label 颜色那么灰, 看起来很难受, 调整成紫色 */
:deep(.v-field--active:not(.v-field--focused) label) {
  color: darkmagenta;
  opacity: 1;
}

:deep(.v-checkbox label) {
  opacity: 0.9;
}
</style>
