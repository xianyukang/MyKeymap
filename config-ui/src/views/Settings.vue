<script setup lang="ts">
import { storeToRefs } from "pinia";
import Table from "@/components/Table.vue";
import { ref } from "vue";
import { useConfigStore } from "@/store/config";

const { customKeymaps, customParentKeymaps, customSonKeymaps, options } = storeToRefs(useConfigStore())
const { getKeymapById, toggleKeymapEnable, addKeymap, removeKeymap } = useConfigStore()

const currId = ref(0);

const checkKeymapData = (keymap: Keymap) => {
  currId.value = useConfigStore().checkKeymapData(keymap)
}

const cantToggleKeymapEnable = (keymap: Keymap) => {
  // 如果名称热键为空不允许启动
  if (keymap.name == '' || keymap.hotkey == '') {
    return true
  }

  // 当前模式作为前置键且有子键启动的情况不允许关闭
  if (customKeymaps.value.filter(k => k.enable && k.parentID == keymap.id).length != 0) {
    return true
  }
}

const cantRemoveKeymap = (keymap: Keymap) => {
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
        <Table class="text-left">
          <tr>
            <th>名称</th>
            <th>热键</th>
            <th>前置键</th>
            <th>选项</th>
          </tr>
          <tr :class="currId == keymap.id ? 'bg-blue-lighten-4' : ''"
              @click="currId = keymap.id"
              v-for="keymap in customKeymaps" :key="keymap.name">
            <td>
              <v-text-field v-model="keymap.name" variant="plain"
                            style="width: 6rem"></v-text-field>
            </td>
            <td>
              <v-text-field v-model="keymap.hotkey" @blur="checkKeymapData(keymap)" variant="plain"
                            style="width: 4rem"></v-text-field>
            </td>
            <td>
              <v-autocomplete v-model="keymap.parentID"
                              :model-value="getKeymapById(keymap.parentID).name"
                              :items="customParentKeymaps" :item-title="item => item.name"
                              :item-value="item => item.id" @blur="checkKeymapData(keymap)"
                              variant="plain" menu-icon="" style="width: 6rem">
              </v-autocomplete>

            </td>
            <td class="w-25">
              <div class="d-flex justify-space-around align-center">
                <v-tooltip :text="cantToggleKeymapEnable(keymap) ? '禁用子键后才可以关闭该热键' : keymap.enable ? '禁用该热键' : '启动该热键'">
                  <template #activator="{props}">
                    <div v-bind="props">
                      <v-switch hide-details color="primary" :model-value="keymap.enable"
                                :disabled="cantToggleKeymapEnable(keymap)"
                                @click="toggleKeymapEnable(keymap)"></v-switch>
                    </div>
                  </template>
                </v-tooltip>
                <v-tooltip :text="cantRemoveKeymap(keymap) ? '删除子键或禁用该热键后再删除' : '删除当前热键'">
                  <template #activator="{props}">
                    <div v-bind="props">
                    <v-btn icon="mdi-delete-outline" variant="text" width="40" height="40"
                           :disabled="cantRemoveKeymap(keymap)"
                           @click="removeKeymap(keymap.id)"></v-btn>
                    </div>
                  </template>
                </v-tooltip>
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
                    <v-text-field :model-value="options.mouse.delay1" variant="underlined"
                                  type="number"
                                  step=".01" maxlength="5"
                                  label="进入连续移动前的延时(秒)"></v-text-field>
                  </v-col>
                  <v-col class="pl-1">
                    <v-text-field :model-value="options.mouse.delay2" variant="underlined"
                                  type="number"
                                  step=".01" maxlength="5"
                                  label="两次移动的间隔时间(秒)"></v-text-field>
                  </v-col>
                </v-row>
                <v-row class="mouseRow" no-gutters>
                  <v-col>
                    <v-text-field :model-value="options.mouse.fastRepeat" variant="underlined"
                                  type="number"
                                  step="1" maxlength="5"
                                  label="快速模式步长(像素)"></v-text-field>
                  </v-col>
                  <v-col>
                    <v-text-field :model-value="options.mouse.fastSingle" variant="underlined"
                                  type="number"
                                  step="1" maxlength="5"
                                  label="快速模式首步长(像素)"></v-text-field>
                  </v-col>
                </v-row>
                <v-row class="mouseRow" no-gutters>
                  <v-col>
                    <v-text-field :model-value="options.mouse.slowRepeat" variant="underlined"
                                  type="number"
                                  step="1" maxlength="5"
                                  label="慢速模式步长(像素)"></v-text-field>
                  </v-col>
                  <v-col>
                    <v-text-field :model-value="options.mouse.slowSingle" variant="underlined"
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
                <v-text-field :model-value="options.scroll.delay1" variant="underlined"
                              type="number"
                              step=".01" maxlength="5"
                              label="进入连续滚动前的延时 (秒)"></v-text-field>
                <v-text-field :model-value="options.scroll.delay2" variant="underlined"
                              type="number"
                              step=".01" maxlength="5"
                              label="两次滚动的间隔时间 (越小滚动速度越快)"></v-text-field>
                <v-text-field :model-value="options.scroll.onceLineCount" variant="underlined"
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

table .v-switch :deep(.v-selection-control) {
  min-height: auto;
}

table .v-autocomplete :deep(.v-field__input) {
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

.mouseRow .v-col:last-child {
  padding-lift: 6px;
}

</style>
