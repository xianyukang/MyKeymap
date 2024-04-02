<script setup lang="ts">
import Table from "@/components/Table.vue";
import Tip from "@/components/Tip.vue";

import { storeToRefs } from "pinia";
import { ref } from "vue";
import { useConfigStore } from "@/store/config";
import { Keymap } from "@/types/config";
// import PathDialog from "@/components/dialog/PathDialog.vue";
import WindowGroupDialog from "@/components/dialog/WindowGroupDialog.vue";
import findLastIndex from "lodash-es/findLastIndex";
import { server } from "@/store/server";
import { computed } from "@vue/reactivity";
import { languageList } from "@/store/language-map";

const { customKeymaps, customParentKeymaps, customSonKeymaps, options, keymaps } = storeToRefs(useConfigStore())
const { translate } = useConfigStore()


const currId = ref(0)

const showMouseOption = ref(false)
const showLanguageOption = ref(false)
const showKeyboardLayout = ref(false)
const showKeymapDelay = ref(true)
const showSkin = ref(false)
const resetOtherToFalse = (newValue: boolean) => {
  [showMouseOption, showLanguageOption, showKeyboardLayout, showKeymapDelay, showSkin].forEach(x => x.value = false)
  return newValue
}

const skin = computed(() => {
  return [
    [
      { key: "windowWidth", label: translate('label:743'), },
      { key: "windowYPos", label: translate('label:744'), },
      { key: "borderRadius", label: translate('label:745'), },
      { key: "hideAnimationDuration", label: translate('label:746'), },
    ],
    [
      { key: "backgroundColor", label: translate('label:747'), },
      { key: "backgroundOpacity", label: translate('label:748'), },
      { key: "gridlineColor", label: translate('label:749'), },
      { key: "gridlineOpacity", label: translate('label:748'), },
    ],
    [
      { key: "borderWidth", label: translate('label:750'), },
      { key: "borderColor", label: translate('label:751'), },
      { key: "borderOpacity", label: translate('label:748'), },
    ],
    [
      { key: "keyColor", label: translate('label:752') },
      { key: "keyOpacity", label: translate('label:748'), },
      { key: "cornerColor", label: translate('label:753'), },
      { key: "cornerOpacity", label: translate('label:748'), },
    ],
    [
      { key: "windowShadowSize", label: translate('label:754'), },
      { key: "windowShadowColor", label: translate('label:755'), },
      { key: "windowShadowOpacity", label: translate('label:748'), },
    ],
]
})

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
    isNew: true,
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
          <Table class="text-left" :titles="[translate('label:501'), translate('label:502'), translate('label:503'), translate('label:504')]">
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
            <v-btn class="ma-3 text-none" color="green" @click="addKeymap()">{{ translate('label:405') }}</v-btn>
          </div>
        </v-card>
      </v-col>
      <v-col class="ml-5 mr-3">
        <div class="otherSetting">
          <v-row :dense="true">
            <v-col>
              <v-card :title="translate('label:505')" min-width="180">
                <v-card-text>
                  <v-switch :label="translate('label:506')" color="primary"
                            :model-value="options.startup"
                            @change="onStartupChange"></v-switch>
                  <!-- <path-dialog/> -->
                  <v-btn class="mt-3 mr-2 text-none" width="170" color="blue" variant="outlined" @click="showLanguageOption = resetOtherToFalse(!showLanguageOption)">{{ translate('label:781') }}</v-btn>
                  <!-- <span class="mr-2"></span> -->
                  <window-group-dialog/>
                  <br/>
                  <v-btn class="mt-3 mr-2 text-none" width="170" color="blue" variant="outlined" @click="showMouseOption = resetOtherToFalse(!showMouseOption)">{{ translate('label:701') }}</v-btn>
                  <v-btn class="mt-3 mr-2 text-none" width="170" color="blue" variant="outlined" @click="showKeyboardLayout = resetOtherToFalse(!showKeyboardLayout)">{{ translate('label:721') }}</v-btn>
                  <v-btn class="mt-3 mr-2 text-none" width="170" color="blue" variant="outlined" @click="showSkin = resetOtherToFalse(!showSkin)">{{ translate('label:741') }}</v-btn>
                  <v-btn class="mt-3 mr-2 text-none" width="170" color="blue" variant="outlined" @click="showKeymapDelay = resetOtherToFalse(!showKeymapDelay)">{{ translate('label:761') }}</v-btn>
                </v-card-text>
              </v-card>
            </v-col>
          </v-row>
            <v-row :dense="true" v-show="showMouseOption">
              <v-col>
                <v-card :title="translate('label:702')" min-width="350">
                  <v-card-text>
                    <v-row class="mouseRow" no-gutters>
                      <v-col>
                        <v-text-field v-model="options.mouse.delay1" variant="underlined"
                                      type="number" step=".01" maxlength="5" color="primary"
                                      :label="translate('label:703')"></v-text-field>
                      </v-col>
                      <v-col>
                        <v-text-field v-model="options.mouse.delay2" variant="underlined"
                                      type="number" step=".01" maxlength="5" color="primary"
                                      :label="translate('label:704')"></v-text-field>
                      </v-col>
                    </v-row>
                    <v-row class="mouseRow" no-gutters>
                      <v-col>
                        <v-text-field v-model="options.mouse.fastRepeat" variant="underlined"
                                      type="number" step="1" maxlength="5" color="primary"
                                      :label="translate('label:705')"></v-text-field>
                      </v-col>
                      <v-col>
                        <v-text-field v-model="options.mouse.fastSingle" variant="underlined"
                                      type="number" step="1" maxlength="5" color="primary"
                                      :label="translate('label:706')"></v-text-field>
                      </v-col>
                    </v-row>
                    <v-row class="mouseRow" no-gutters>
                      <v-col>
                        <v-text-field v-model="options.mouse.slowRepeat" variant="underlined"
                                      type="number" step="1" maxlength="5" color="primary"
                                      :label="translate('label:707')"></v-text-field>
                      </v-col>
                      <v-col>
                        <v-text-field v-model="options.mouse.slowSingle" variant="underlined"
                                      type="number" step="1" maxlength="5" color="primary"
                                      :label="translate('label:708')"></v-text-field>
                      </v-col>
                    </v-row>
                    <v-row class="mouseRow" no-gutters>
                      <v-col>
                        <v-text-field v-model="options.mouse.tipSymbol" variant="underlined" color="primary" :label="translate('label:709')"></v-text-field>
                      </v-col>
                      <v-col>
                        <br>
                        <!-- <v-label>备选符号: 🖱️🔘</v-label> -->
                      </v-col>
                    </v-row>
                    <v-row>
                      <v-col>
                        <v-checkbox :label="translate('label:710')" color="secondary" hide-details density="compact" v-model="options.mouse.showTip" />
                        <v-checkbox :label="translate('label:711')" color="secondary" hide-details density="compact" v-model="options.mouse.keepMouseMode" />
                      </v-col>
                    </v-row>
                  </v-card-text>
                </v-card>
              </v-col>
              <v-col>
                <v-card :title="translate('label:712')" min-width="180">
                  <v-card-text>
                    <v-text-field v-model="options.scroll.delay1" variant="underlined"
                                  type="number" step=".01" maxlength="5" color="primary"
                                  :label="translate('label:713')"></v-text-field>
                    <v-text-field v-model="options.scroll.delay2" variant="underlined"
                                  type="number" step=".01" maxlength="5" color="primary"
                                  :label="translate('label:714')"></v-text-field>
                    <v-text-field v-model="options.scroll.onceLineCount" variant="underlined"
                                  type="number" step="1" maxlength="5" color="primary"
                                  :label="translate('label:715')"></v-text-field>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
            <v-row v-show="showKeyboardLayout">
              <v-col>
                <v-card :title="translate('label:722')" elevation="2">
                  <v-card-text>
                    <v-textarea color="primary" variant="underlined" auto-grow rows="4" v-model="options.keyboardLayout"></v-textarea>
                  </v-card-text>
                  <v-card-actions class="d-flex justify-end">
                    <v-btn class="text-none" variant="outlined" color="green" @click="useConfigStore().resetKeyboardLayout(0)">{{ translate('label:723') }}</v-btn>
                    <v-btn class="text-none" variant="outlined" color="green" @click="useConfigStore().resetKeyboardLayout(74)">{{ translate('label:724') }}</v-btn>
                    <v-btn class="text-none" variant="outlined" color="green" @click="useConfigStore().resetKeyboardLayout(104)">{{ translate('label:725') }}</v-btn>
                    <v-btn class="text-none" variant="outlined" color="blue" @click="useConfigStore().resetKeyboardLayout(1)">{{ translate('label:726') }}</v-btn>
                  </v-card-actions>
                </v-card>
              </v-col>
            </v-row>
            <v-row v-show="showLanguageOption">
              <v-col>
                <v-card elevation="2">
                  <v-card-text>
                    <v-select :items="languageList" v-model="options.language" variant="outlined"></v-select>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
            <v-row v-show="showKeymapDelay">
              <v-col>
                <v-card :title="translate('label:762')" elevation="2">
                  <v-card-text>
                    {{ translate('label:763') }}<br>
                    {{ translate('label:764') }}<br>
                    {{ translate('label:765') }}<br>
                    &nbsp;
                    <v-row>
                      <v-col cols="3" v-for="keymap in customKeymaps" :key="keymap.id">
                        <v-text-field v-model.number="keymap.delay" variant="underlined"
                                      type="number" step="1" maxlength="5" min="0" color="primary"
                                      :label="keymap.name" :class="{'positive-number': keymap.delay > 0}"></v-text-field>
                      </v-col>
                    </v-row>
                  </v-card-text>
                </v-card>
              </v-col>
            </v-row>
            <v-row v-show="showSkin">
              <v-col>
                <v-card :title="translate('label:742')" elevation="2">
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

.positive-number {
  color: #d05;
}
</style>
