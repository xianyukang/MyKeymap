<script setup lang="ts">

import Table from "@/components/Table.vue";
import { storeToRefs } from "pinia";
import { useConfigStore } from "@/store/config";
import { ref } from "vue";
import ActionView from "@/components/actions/Action.vue";
import { Action } from "@/types/config";

const { hotkeys, windowGroupID } = storeToRefs(useConfigStore())
const { translate } = useConfigStore()

const currHotkey = ref<string>("")
const changeCustomHotkey = (hotkey: string, newHotkey: string) => {
  useConfigStore().changeHotkey(hotkey, newHotkey)
  checkRow(newHotkey)
}

const checkRow = (hotkey: string, windowGroupId?: number) => {
  currHotkey.value = hotkey
  useConfigStore().hotkey = hotkey
  if (windowGroupId != undefined) {
    useConfigStore().windowGroupID = windowGroupId
  }
}

const removeCustomHotkey = (hotkey: string) => {
  useConfigStore().removeHotkey(hotkey);
  if (currHotkey.value == hotkey) {
    checkRow("")
  }
}

const getActionComment = (action: Array<Action>) => {
  return action.find(a => !a.isEmpty && a.windowGroupID == windowGroupID.value)?.comment ?? ''
}

const getActionWindowGroupId = (action: Array<Action>) => {
  return windowGroupID.value
}

</script>

<template>
  <v-row class="mt-2" justify="center" :dense="true">
    <v-col sm="auto">
      <v-card width="400">
        <Table class="text-left" :titles="[translate('label:404'), translate('label:305'), '']">
          <tr :class="currHotkey == hotkey ? 'bg-blue-lighten-4' : ''"
              @click="checkRow(hotkey as string, getActionWindowGroupId(action))"
              v-for="(action, hotkey, index) in hotkeys" :key="index">
            <td style="width: 20%">
              <v-text-field :model-value="hotkey" placeholder="此处修改"
                            @change="changeCustomHotkey(hotkey as string, $event.target.value)"
                            variant="plain" style="width: 6rem"></v-text-field>
            </td>
            <td style="width: 60%; cursor: pointer;" class="text-pre overflow-hidden"><div style="width: 0;">{{ translate(getActionComment(action)) }}</div></td>
            <td style="width: 20%">
              <v-btn icon="mdi-delete-outline" variant="text" width="40" height="40"
                     @click.stop="removeCustomHotkey(hotkey as string)"></v-btn>
            </td>
          </tr>
        </Table>

        <div class="d-flex justify-end">
          <v-btn class="ma-3 text-none" color="green" @click="useConfigStore().addHotKey()">{{ translate('label:405') }}</v-btn>
        </div>
      </v-card>
    </v-col>
    <v-col>
      <!--和下面的选择功能面板对其-->
      <v-row justify="center" :dense="true" style="width: 810px">
        <!-- <v-col>
          <v-card title="简述">
            <v-card-text>
              <p>如果想设置 Alt + C 这样的热键:</p>
              <p>(1) 点击添加一行</p>
              <p>(2) 在热键那一列里填 !c</p>
              <br>
              <br>
              <p>(英文感叹号 ! 用于表示 Alt 键</p>
            </v-card-text>
          </v-card>
        </v-col> -->
        <v-col>
          <v-card title="Example 1">
            <v-card-text>
              <p>!c = Alt + C</p>
              <p>#c = Win + C</p>
              <p>^c = Ctrl + C</p>
              <p>^!c = Ctrl + Alt + C</p>
              <p>^+c = Ctrl + Shift + C</p>
              <p>+!c = Shift + Alt + C</p>
            </v-card-text>
          </v-card>
        </v-col>
        <v-col>
          <v-card title="Example 2">
            <v-card-text>
              <p>F11 = F11</p>
              <p>!1 &nbsp;= Alt + 1</p>
              <p>+F2 = Shift + F2</p>
              <p>!space = Alt + Space</p>

              <br>
              <p>更多特殊按键参考: <a target="_blank"
                                  href="https://wyagd001.github.io/v2/docs/KeyList.htm#keyboard"
                                  style="color: green; text-decoration: none">reference</a></p>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
      <ActionView />
    </v-col>
  </v-row>
</template>

<style scoped>
table .v-text-field :deep(input) {
  min-height: auto;
  padding: 0 !important;
}

table .v-text-field :deep(.v-input__details) {
  min-height: auto;
  height: 0 !important;
}

table .v-switch :deep(.v-selection-control) {
  min-height: auto;
}

table .v-select :deep(.v-field__input) {
  padding: 0;
}

table .v-autocomplete :deep(input) {
  top: 13px
}
</style>
