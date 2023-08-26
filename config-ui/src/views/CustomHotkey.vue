<script setup lang="ts">

import Table from "@/components/Table.vue";
import { storeToRefs } from "pinia";
import { useConfigStore } from "@/store/config";
import { ref } from "vue";
import Action from "@/actions/Action.vue";

const { hotkeys } = storeToRefs(useConfigStore())

const currHotkey = ref<string>("")
const changeCustomHotkey = (hotkey: string, newHotkey: string) => {
  useConfigStore().changeHotkey(hotkey, newHotkey)
  checkRow(newHotkey)
}

const checkRow = (hotkey: string) => {
  currHotkey.value = hotkey
  useConfigStore().hotkey = hotkey
}

const removeCustomHotkey = (hotkey: string) => {
  useConfigStore().removeHotkey(hotkey);
  if (currHotkey.value == hotkey) {
    checkRow("")
  }
}

</script>

<template>
  <v-row class="mt-2" justify="center" :dense="true">
    <v-col sm="auto">
      <v-card width="400">
        <Table class="text-left" :titles="['热键', '备注', '选项']">
          <tr :class="currHotkey == hotkey ? 'bg-blue-lighten-4' : ''"
              @click="checkRow(hotkey as string)"
              v-for="(action, hotkey, index) in hotkeys" :key="index">
            <td style="width: 20%">
              <v-text-field :model-value="hotkey"
                            @change="changeCustomHotkey(hotkey as string, $event.target.value)"
                            variant="plain" style="width: 6rem"></v-text-field>
            </td>
            <td style="width: 60%">{{ action[0].comment }}</td>
            <td style="width: 20%">
              <v-btn icon="mdi-delete-outline" variant="text" width="40" height="40"
                     @click.stop="removeCustomHotkey(hotkey as string)"></v-btn>
            </td>
          </tr>
        </Table>

        <div class="d-flex justify-end">
          <v-btn class="ma-3" color="green" @click="useConfigStore().addHotKey()">新增热键</v-btn>
        </div>
      </v-card>
    </v-col>
    <v-col>
      <!--和下面的选择功能面板对其-->
      <v-row justify="center" :dense="true" style="width: 810px">
        <v-col>
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
        </v-col>
        <v-col>
          <v-card title="示例1">
            <v-card-text>
              <p>!c 表示 Alt + C</p>
              <p>#c 表示 Win + C</p>
              <p>^c 表示 Ctrl + C</p>
              <p>^!c 表示 Ctrl + Alt + C</p>
              <p>^+c 表示 Ctrl + Shift + C</p>
              <p>+!c 表示 Shift + Alt + C</p>
            </v-card-text>
          </v-card>
        </v-col>
        <v-col>
          <v-card title="示例2">
            <v-card-text>
              <p>F11 表示 F11</p>
              <p>!1 表示 Alt + 1</p>
              <p>!space 表示 Alt + Space</p>
              <p>+F2 表示 Shift + F2</p>
              <p>(更多特殊按键 <a target="_blank"
                                  href="https://wyagd001.github.io/zh-cn/docs/KeyList.htm#keyboard"
                                  style="color: green; text-decoration: none">参考这里</a></p>
              <p>(注意符号不要用中文标点符号</p>
            </v-card-text>
          </v-card>
        </v-col>
      </v-row>
      <Action/>
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
