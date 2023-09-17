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
import { server } from "@/store/server";

const { customKeymaps, customParentKeymaps, customSonKeymaps, options, keymaps } = storeToRefs(useConfigStore())


const currId = ref(0)

const showMouseOption = ref(false)
const showKeyboardLayout = ref(false)
const showKeymapDelay = ref(false)
const showSkin = ref(false)
const resetOtherToFalse = (newValue: boolean) => {
  [showMouseOption, showKeyboardLayout, showKeymapDelay, showSkin].forEach(x => x.value = false)
  return newValue
}

const skin = [
  [
    { key: "windowWidth", label: "窗口宽度", },
    { key: "windowYPos", label: "窗口 Y 轴位置 (百分比)", },
    { key: "borderRadius", label: "窗口圆角大小", },
    { key: "hideAnimationDuration", label: "窗口动画持续时间", },
  ],
  [
    { key: "backgroundColor", label: "窗口背景色", },
    { key: "backgroundOpacity", label: "透明度", },
    { key: "gridlineColor", label: "网格线颜色", },
    { key: "gridlineOpacity", label: "透明度", },
  ],
  [
    { key: "borderWidth", label: "边框宽度", },
    { key: "borderColor", label: "边框颜色", },
    { key: "borderOpacity", label: "透明度", },
  ],
  [
    { key: "keyColor", label: "按键颜色" },
    { key: "keyOpacity", label: "透明度", },
    { key: "cornerColor", label: "四角颜色", },
    { key: "cornerOpacity", label: "透明度", },
  ],
  [
    { key: "windowShadowSize", label: "窗口阴影大小", },
    { key: "windowShadowColor", label: "窗口阴影颜色", },
    { key: "windowShadowOpacity", label: "透明度", },
  ],
]

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
  useConfigStore().changeAbbrEnable()
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
    delay: 0,
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

function onStartupChange() {
  options.value.startup = !options.value.startup
  if (options.value.startup) {
    server.enableRunAtStartup()
  } else {
    server.disableRunAtStartup()
  }
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
                <v-select v-model="keymap.parentID" :items="customParentKeymaps.filter(c => c.id != keymap.id)"
                          :item-title="item => item.name"
                          :item-value="item => item.id" :disabled="hasSubKeymap(keymap)"
                          item-color="blue"
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
                            @change="onStartupChange"></v-switch>
                  <path-dialog/>
                  <span class="mr-2"></span>
                  <window-group-dialog/>
                  <br/>
                  <v-btn class="mt-3 mr-2" width="170" color="blue" variant="outlined" @click="showMouseOption = resetOtherToFalse(!showMouseOption)">🖱️ 修改鼠标参数</v-btn>
                  <v-btn class="mt-3 mr-2" width="170" color="blue" variant="outlined" @click="showKeyboardLayout = resetOtherToFalse(!showKeyboardLayout)">⌨️ 修改键盘布局</v-btn>
                  <v-btn class="mt-3 mr-2" width="170" color="blue" variant="outlined" @click="showSkin = resetOtherToFalse(!showSkin)">✨ 命令框皮肤</v-btn>
                  <v-btn class="mt-3 mr-2" width="170" color="blue" variant="outlined" @click="showKeymapDelay = resetOtherToFalse(!showKeymapDelay)">🕗 设置触发延时</v-btn>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>
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
                    <v-row class="mouseRow" no-gutters>
                      <v-col>
                        <v-text-field v-model="options.mouse.tipSymbol" variant="underlined" color="primary" label="鼠标模式的提示符"></v-text-field>
                      </v-col>
                      <v-col>
                        <br>
                        <v-label>备选符号: 🖱️🔘</v-label>
                      </v-col>
                    </v-row>
                    <v-row>
                      <v-col>
                        <v-checkbox label="提示进入了鼠标模式" color="secondary" hide-details density="compact" v-model="options.mouse.showTip" />
                        <v-checkbox label="点击鼠标后不退出鼠标模式" color="secondary" hide-details density="compact" v-model="options.mouse.keepMouseMode" />
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
                                  label="一次滚动的行数"></v-text-field>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
            <v-row v-show="showKeyboardLayout">
              <v-col>
                <v-card title="键盘布局" elevation="2">
                  <v-card-text>
                    <v-textarea color="primary" variant="underlined" auto-grow rows="4" v-model="options.keyboardLayout"></v-textarea>
                  </v-card-text>
                  <v-card-actions class="d-flex justify-end">
                    <v-btn variant="outlined" color="green" @click="useConfigStore().resetKeyboardLayout(0)">重置为默认值</v-btn>
                    <v-btn variant="outlined" color="green" @click="useConfigStore().resetKeyboardLayout(74)">重置为 74 键</v-btn>
                    <v-btn variant="outlined" color="green" @click="useConfigStore().resetKeyboardLayout(104)">重置为 104 键</v-btn>
                    <v-btn variant="outlined" color="blue" @click="useConfigStore().resetKeyboardLayout(1)">添加鼠标按钮</v-btn>
                  </v-card-actions>
                </v-card>
              </v-col>
            </v-row>
            <v-row v-show="showKeymapDelay">
              <v-col>
                <v-card title="触发延时 (单位: 毫秒)" elevation="2">
                  <v-card-text>
                    一般推荐设为 0，让模式立刻生效。<br>
                    如果设置大于零的值，短按会执行按键原有功能，长按则触发模式，也许能减少打字误触。<br>
                    设置长按触发，会有另一种形式的误触，比如想输入热键，但长按时间不够，所以触发热键失败。<br>
                    &nbsp;
                    <v-row>
                      <v-col cols="3" v-for="keymap in customKeymaps" :key="keymap.id">
                        <v-text-field v-model.number="keymap.delay" variant="underlined"
                                      type="number" step="1" maxlength="5" min="0" color="primary"
                                      :label="keymap.name"></v-text-field>
                      </v-col>
                    </v-row>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
            <v-row v-show="showSkin">
              <v-col>
                <v-card title="命令框皮肤" elevation="2">
                  <v-card-text>
                    <v-row v-for="(row, index) in skin" :key="index">
                      <v-col cols="3" v-for="item in row" :key="item.key">
                        <v-text-field v-model="options.commandInputSkin[item.key]" variant="underlined" color="primary" :label="item.label"></v-text-field>
                      </v-col>
                    </v-row>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
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

.v-text-field :deep(label),.v-switch :deep(label),.v-checkbox :deep(label) {
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
