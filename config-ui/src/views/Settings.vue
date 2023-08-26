<script setup lang="ts">
import Table from "@/components/Table.vue";
import Tip from "@/components/Tip.vue";

import { storeToRefs } from "pinia";
import { onMounted, ref } from "vue";
import { useConfigStore } from "@/store/config";
import { Keymap } from "@/types/config";

const { customKeymaps, customParentKeymaps, customSonKeymaps, options } = storeToRefs(useConfigStore())
const { toggleKeymapEnable, addKeymap, removeKeymap } = useConfigStore()

// TODO: 设置页面的加载时间似乎需要 150 - 200 ms
// const time1 = Date.now()
// onMounted(() => {
//   const time2 = Date.now()
//   console.log(time2 - time1)
// })

const currId = ref(0);

const checkKeymapData = (keymap: Keymap) => {
  currId.value = useConfigStore().checkKeymapData(keymap)
}

const disabledKeymapEnable = (keymap: Keymap) => {
  // 如果名称热键为空不允许启动
  if (keymap.name == '' || keymap.hotkey == '') {
    return true
  }

  // 当前模式作为前置键且有子键启动的情况不允许关闭
  return customKeymaps.value.filter(k => k.enable && k.parentID == keymap.id).length != 0
}

const disabledKeymapOption = (keymap: Keymap) => {
  // 状态为启动时、被作为前置键不允许删除
  if (keymap.enable) {
    return true
  }
  return customSonKeymaps.value.findIndex(k => k.parentID == keymap.id) != -1
}
</script>

<template>
  <v-row class="mt-2" justify="center" :dense="true">
    <v-col sm="auto">
      <v-card width="500">
        <Table class="text-left" :titles="['名称', '热键', '前置键', '选项']">
          <tr :class="currId == keymap.id ? 'bg-blue-lighten-4' : ''"
              @click="currId = keymap.id"
              v-for="keymap in customKeymaps" :key="keymap.id">
            <td>
              <tip :text="keymap.enable ? '已启动禁止修改' : '修改名称'">
                <v-text-field v-model.lazy="keymap.name" @blur="checkKeymapData(keymap)"
                              :disabled="keymap.enable" variant="plain"
                              style="width: 6rem"></v-text-field>
              </tip>
            </td>
            <td>
              <tip :text="keymap.enable ? '已启动禁止修改' : '修改热键'">
                <v-text-field v-model.lazy="keymap.hotkey" @blur="checkKeymapData(keymap)"
                              :disabled="keymap.enable" variant="plain"
                              style="width: 4rem"></v-text-field>
              </tip>
            </td>
            <td>
              <tip :text="disabledKeymapOption(keymap) ? '已启动或有子键不允许更改' : '更改前置键'">
                <v-select v-model="keymap.parentID" :items="customParentKeymaps" :item-title="item => item.name"
                          :item-value="item => item.id" :disabled="disabledKeymapOption(keymap)"
                          variant="plain" style="width: 6rem">
                </v-select>
              </tip>
            </td>
            <td class="w-25">
              <div class="d-flex justify-space-around align-center">
                <tip :text="disabledKeymapEnable(keymap) ? keymap.enable ? '请禁用子键' : '请输入名称和热键' : keymap.enable ? '禁用该热键' : '启动该热键'">
                  <v-switch hide-details color="primary" :model-value="keymap.enable"
                            :disabled="disabledKeymapEnable(keymap)"
                            @click="toggleKeymapEnable(keymap)"></v-switch>
                </tip>
                <tip :text="disabledKeymapOption(keymap) ? '请删除子键或禁用该热键' : '删除当前热键'">
                  <v-btn icon="mdi-delete-outline" variant="text" width="40" height="40"
                         :disabled="disabledKeymapOption(keymap)"
                         @click="removeKeymap(keymap.id)"></v-btn>
                </tip>
              </div>
            </td>
          </tr>
        </Table>

        <div class="d-flex justify-end">
          <v-btn class="ma-3" color="green" @click="addKeymap()">新增热键</v-btn>
        </div>
      </v-card>
    </v-col>
    <v-col sm="7">
      <div class="otherSetting">
        <v-row :dense="true">
          <v-col>
            <v-card title="按键重映射" min-width="350">
              <v-card-text>
                <a target="_blank" href="https://wyagd001.github.io/zh-cn/docs/KeyList.htm#keyboard"
                   style="color: green; text-decoration: none">键名可以查阅此处</a>
                <p>如果想把右 Alt 重映射为左 Ctrl 键:</p>
                <p>①在下面添加一行 <code
                    style="color: #d05; border: 1px solid #ddd; padding: 1px 6px;">RAlt::LCtrl</code>
                  就行</p>
                <p>②删掉对应的行则取消映射</p>
                <p>③<a target="_blank" href="RemapKeyExample.html"
                       style="color: green; text-decoration: none">能为不同软件设置不同的映射</a>
                </p>
                <v-textarea v-model="options.keyMapping" variant="outlined" shaped auto-grow
                            rows="3"></v-textarea>
              </v-card-text>
            </v-card>
          </v-col>
          <v-col>
            <v-card title="其他设置">
              <v-card-text>
                <v-switch label="开机自启" messages="可能需要关掉再开启才生效" color="primary"
                          :model-value="options.startup"
                          @change="options.startup = !options.startup"></v-switch>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
        <v-row :dense="true">
          <v-col>
            <v-card title="鼠标移动相关参数" min-width="350">
              <v-card-text>
                <v-row class="mouseRow" no-gutters>
                  <v-col class="pr-1">
                    <v-text-field v-model="options.mouse.delay1" variant="underlined"
                                  type="number"
                                  step=".01" maxlength="5"
                                  label="进入连续移动前的延时(秒)"></v-text-field>
                  </v-col>
                  <v-col class="pl-1">
                    <v-text-field v-model="options.mouse.delay2" variant="underlined"
                                  type="number"
                                  step=".01" maxlength="5"
                                  label="两次移动的间隔时间(秒)"></v-text-field>
                  </v-col>
                </v-row>
                <v-row class="mouseRow" no-gutters>
                  <v-col>
                    <v-text-field v-model="options.mouse.fastRepeat" variant="underlined"
                                  type="number"
                                  step="1" maxlength="5"
                                  label="快速模式步长(像素)"></v-text-field>
                  </v-col>
                  <v-col>
                    <v-text-field v-model="options.mouse.fastSingle" variant="underlined"
                                  type="number"
                                  step="1" maxlength="5"
                                  label="快速模式首步长(像素)"></v-text-field>
                  </v-col>
                </v-row>
                <v-row class="mouseRow" no-gutters>
                  <v-col>
                    <v-text-field v-model="options.mouse.slowRepeat" variant="underlined"
                                  type="number"
                                  step="1" maxlength="5"
                                  label="慢速模式步长(像素)"></v-text-field>
                  </v-col>
                  <v-col>
                    <v-text-field v-model="options.mouse.slowSingle" variant="underlined"
                                  type="number"
                                  step="1" maxlength="5"
                                  label="慢速模式首步长(像素)"></v-text-field>
                  </v-col>
                </v-row>
              </v-card-text>
            </v-card>
          </v-col>
          <v-col>
            <v-card title="滚轮相关参数" min-width="200">
              <v-card-text>
                <v-text-field v-model="options.scroll.delay1" variant="underlined"
                              type="number"
                              step=".01" maxlength="5"
                              label="进入连续滚动前的延时 (秒)"></v-text-field>
                <v-text-field v-model="options.scroll.delay2" variant="underlined"
                              type="number"
                              step=".01" maxlength="5"
                              label="两次滚动的间隔时间 (越小滚动速度越快)"></v-text-field>
                <v-text-field v-model="options.scroll.onceLineCount" variant="underlined"
                              type="number" step="1" maxlength="5"
                              label="单次滑动参数"></v-text-field>
              </v-card-text>
            </v-card>
          </v-col>
        </v-row>
      </div>
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

table .v-text-field :deep(.v-field--disabled) {
  opacity: 1 !important;
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

.otherSetting {
  margin-right: 20px;
}

.otherSetting .v-card {
  margin-bottom: 10px;
}

.mouseRow .v-col:first-child {
  padding-right: 6px;
}
</style>
