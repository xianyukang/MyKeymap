<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import ActivateOrRun from '@/components/actions/ActivateOrRun.vue'
import System from '@/components/actions/System.vue'
import Window from '@/components/actions/Window.vue'
import Mouse from '@/components/actions/Mouse.vue'
import RemapKey from '@/components/actions/RemapKey.vue'
import SendKey from '@/components/actions/SendKey.vue'
import Text from '@/components/actions/Text.vue'
import BuiltinFunction from '@/components/actions/BuiltinFunction.vue'
import MyKeymap from '@/components/actions/MyKeymap.vue'
import { Action, Keymap } from "@/types/config";


const { config, keymap, action, windowGroupID, hotkey } = storeToRefs(useConfigStore())
const { translate } = useConfigStore()

const actionTypes = [
  { id: 0, label: "label:200" },
  { id: 1, label: "label:201" },
  { id: 2, label: "label:202" },
  { id: 3, label: "label:203" },
  { id: 4, label: "label:204", hideInAbbr: true },
  { id: 5, label: "label:205", hideInAbbr: true },
  { id: 6, label: "label:206" },
  { id: 7, label: "label:207" },
  { id: 8, label: "label:208" },
  { id: 9, label: "label:209" },
]

function filter(items: typeof actionTypes, keymap: Keymap | undefined): typeof actionTypes {
  items = items.map(x => ({...x, name: translate(x.label)}))
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
      <v-card min-height="530" width="800" elevation="5">
        <v-card-title style="padding-bottom: 0">
          <v-row>
            <v-col cols="5">
              <v-select :items="config!.options.windowGroups.filter(x => x.id >= 0)"
                        item-title="name"
                        item-value="id"
                        v-model="windowGroupID"
                        variant="outlined"
                        :menu-props="{ maxHeight: 900 }"
                        ></v-select>
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
        <v-card-text style="padding-bottom: 0;">
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
