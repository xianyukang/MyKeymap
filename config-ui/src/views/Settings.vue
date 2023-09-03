<script setup lang="ts">
import Table from "@/components/Table.vue";
import Tip from "@/components/Tip.vue";

import { storeToRefs } from "pinia";
import { ref } from "vue";
import { useConfigStore } from "@/store/config";
import { Keymap } from "@/types/config";
import PathDialog from "@/components/dialog/PathDialog.vue";
import WindowGroupDialog from "@/components/dialog/WindowGroupDialog.vue";
import findLastIndex from "lodash-es/findLastIndex";

const { customKeymaps, customParentKeymaps, customSonKeymaps, options, keymaps } = storeToRefs(useConfigStore())

// TODO: 设置页面的加载时间似乎需要 150 - 200 ms
// const time1 = Date.now()
// onMounted(() => {
//   const time2 = Date.now()
//   console.log(time2 - time1)
// })

const currId = ref(0)

const showMouseOption = ref(false)

const checkKeymapData = (keymap: Keymap) => {
  if (keymap.hotkey == "") {
    currId.value = keymap.id
  }
  // 判断当前热键是否已存在，已存在删除当前模式
  const f = keymaps.value.find(k => k.hotkey == keymap.hotkey && k.parentID == keymap.parentID)!
  if (f.id != keymap.id) {
    removeKeymap(keymap.id)
  }
  currId.value = f.id
}

const disabledKeymapOption = (keymap: Keymap) => {
  // 状态为启动时、被作为前置键不允许删除
  if (keymap.enable) {
    return true
  }
  return customSonKeymaps.value.findIndex(k => k.parentID == keymap.id) != -1
}

const hasSubKeymap = (keymap: Keymap) => {
  return customSonKeymaps.value.findIndex(k => k.parentID == keymap.id) != -1
}

const deleteBtnTip = (keymap: Keymap) => {
  if (keymap.enable) {
    return '开启时不允许删除'
  }
  if (customSonKeymaps.value.findIndex(k => k.parentID == keymap.id) != -1) {
    return '被依赖时不允许删除'
  }
  return ''
}

function toggleKeymapEnable(keymap: Keymap) {
  // 开启的keymap有前置键连同前置键一块开启
  if (!keymap.enable && keymap.parentID != 0) {
    customParentKeymaps.value.find(k => k.id == keymap.parentID)!.enable = true
  }

  // 关闭的时候连同子键一块关闭
  if (keymap.enable) {
    customSonKeymaps.value.filter(k => k.parentID == keymap.id).forEach(k => k.enable = false)
  }

  keymap.enable = !keymap.enable
}

function nextKeymapId() {
  const length = customKeymaps.value.length;
  if (length == 0) {
    return 5
  }

  return customKeymaps.value[length - 1].id + 1
}

function addKeymap() {
  const newKeymap: Keymap = {
    id: nextKeymapId(),
    name: "",
    enable: false,
    hotkey: "",
    parentID: 0,
    hotkeys: {}
  }

  keymaps.value.splice(customKeymaps.value.length, 0, newKeymap)
}

function removeKeymap(id: number) {
  removeKeymapByIndex(findLastIndex(keymaps.value, k => k.id == id))
}

function removeKeymapByIndex(index: number) {
  keymaps.value.splice(index, 1)
}
</script>

<template>
  <v-container :fluid="true">
    <v-row>
      <v-col xl="6">
        <v-card width="640" elevation="3">
          <Table class="text-left" :titles="['名称', '触发键', '上层', '开关']">
            <tr :class="currId == keymap.id ? '' : ''"
                @click="currId = keymap.id"
                v-for="keymap in customKeymaps" :key="keymap.id">
              <td>
                <v-text-field v-model.lazy="keymap.name" @blur="checkKeymapData(keymap)"
                              variant="plain" style="width: 9rem"></v-text-field>
              </td>
              <td>
                <v-text-field v-model.lazy="keymap.hotkey" @blur="checkKeymapData(keymap)"
                              variant="plain" style="width: 7rem"></v-text-field>
              </td>
              <td>
                  <v-select v-model="keymap.parentID" :items="customParentKeymaps" :item-title="item => item.name"
                            :item-value="item => item.id" :disabled="hasSubKeymap(keymap)" item-color="blue"
                            variant="plain" style="width: 7rem">
                  </v-select>
              </td>
              <td>
                <div class="d-flex justify-space-between align-center">
                  <v-switch hide-details color="primary" :model-value="keymap.enable"
                            @click="toggleKeymapEnable(keymap)"></v-switch>
                  <tip :text="deleteBtnTip(keymap)">
                    <v-btn icon="mdi-delete-outline" variant="text" width="40" height="40"
                           :disabled="disabledKeymapOption(keymap)"
                           @click="removeKeymap(keymap.id)"></v-btn>
                  </tip>
                </div>
              </td>
            </tr>
          </Table>

          <div class="d-flex justify-end">
            <v-btn class="ma-3" color="green" @click="addKeymap()">新增一个</v-btn>
          </div>
        </v-card>
      </v-col>
      <v-col class="ml-5 mr-3">
        <div class="otherSetting">
          <v-row :dense="true">
            <v-col>
              <v-card title="其他设置" min-width="180">
                <v-card-text>
                  <v-switch label="开机自启" messages="可能需要关掉再开启才生效" color="primary"
                            :model-value="options.startup"
                            @change="options.startup = !options.startup"></v-switch>
                  <path-dialog/>
                  <br/>
                  <window-group-dialog/>
                  <br/>
                  <v-btn class="mt-3" width="170" color="blue" variant="outlined" @click="showMouseOption = !showMouseOption">修改鼠标移动参数</v-btn>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>
          <v-expand-transition>
            <v-row :dense="true" v-show="showMouseOption">
              <v-col>
                <v-card title="鼠标移动相关参数" min-width="350">
                  <v-card-text>
                    <v-row class="mouseRow" no-gutters>
                      <v-col>
                        <v-text-field v-model="options.mouse.delay1" variant="underlined"
                                      type="number" step=".01" maxlength="5" color="primary"
                                      label="进入连续移动前的延时(秒)"></v-text-field>
                      </v-col>
                      <v-col>
                        <v-text-field v-model="options.mouse.delay2" variant="underlined"
                                      type="number" step=".01" maxlength="5" color="primary"
                                      label="两次移动的间隔时间(秒)"></v-text-field>
                      </v-col>
                    </v-row>
                    <v-row class="mouseRow" no-gutters>
                      <v-col>
                        <v-text-field v-model="options.mouse.fastRepeat" variant="underlined"
                                      type="number" step="1" maxlength="5" color="primary"
                                      label="快速模式步长(像素)"></v-text-field>
                      </v-col>
                      <v-col>
                        <v-text-field v-model="options.mouse.fastSingle" variant="underlined"
                                      type="number" step="1" maxlength="5" color="primary"
                                      label="快速模式首步长(像素)"></v-text-field>
                      </v-col>
                    </v-row>
                    <v-row class="mouseRow" no-gutters>
                      <v-col>
                        <v-text-field v-model="options.mouse.slowRepeat" variant="underlined"
                                      type="number" step="1" maxlength="5" color="primary"
                                      label="慢速模式步长(像素)"></v-text-field>
                      </v-col>
                      <v-col>
                        <v-text-field v-model="options.mouse.slowSingle" variant="underlined"
                                      type="number" step="1" maxlength="5" color="primary"
                                      label="慢速模式首步长(像素)"></v-text-field>
                      </v-col>
                    </v-row>
                  </v-card-text>
                </v-card>
              </v-col>
              <v-col>
                <v-card title="滚轮相关参数" min-width="180">
                  <v-card-text>
                    <v-text-field v-model="options.scroll.delay1" variant="underlined"
                                  type="number" step=".01" maxlength="5" color="primary"
                                  label="进入连续滚动前的延时 (秒)"></v-text-field>
                    <v-text-field v-model="options.scroll.delay2" variant="underlined"
                                  type="number" step=".01" maxlength="5" color="primary"
                                  label="两次滚动的间隔时间 (越小滚动速度越快)"></v-text-field>
                    <v-text-field v-model="options.scroll.onceLineCount" variant="underlined"
                                  type="number" step="1" maxlength="5" color="primary"
                                  label="单次滑动参数"></v-text-field>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
          </v-expand-transition>
        </div>
      </v-col>
    </v-row>
    </v-container>
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

table .v-text-field :deep(.v-field--disabled) {
  opacity: 1 !important;
}

.v-text-field :deep(label),.v-switch :deep(label) {
  color: black;
  opacity: 1;
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

.otherSetting .v-card {
  margin-bottom: 10px;
}

.mouseRow .v-col:first-child {
  padding-right: 16px;
}
</style>
