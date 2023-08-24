<script setup lang="ts">
import { storeToRefs } from "pinia";
import Table from "@/components/Table.vue";
import { ref } from "vue";
import { useConfigStore } from "@/store/config";

const { customKeymaps, customParentKeymaps } = storeToRefs(useConfigStore())
const { getKeymapById, toggleKeymapEnable, addKeymap, removeKeymap } = useConfigStore()

const currId = ref(0);

const checkKeymapData = (keymap: Keymap) => {
  currId.value = useConfigStore().checkKeymapData(keymap)
}

</script>

<template>
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
          <v-text-field v-model="keymap.name" variant="plain" style="width: 6rem"></v-text-field>
        </td>
        <td>
          <v-text-field v-model="keymap.hotkey" @blur="checkKeymapData(keymap)" variant="plain" style="width: 4rem"></v-text-field>
        </td>
        <td>
          <v-autocomplete v-model="keymap.parentID" :model-value="getKeymapById(keymap.parentID).name"
                          :items="customParentKeymaps" :item-title="item => item.name"
                          :item-value="item => item.id"
                          variant="plain" menu-icon="" style="width: 6rem">
          </v-autocomplete>

        </td>
        <td class="w-25">
          <div class="d-flex justify-space-around align-center">
            <v-tooltip :text="keymap.enable ? '停用该热键' : '启动该热键'">
              <template #activator>
                <v-switch hide-details color="primary" :model-value="keymap.enable" :disabled="keymap.name == '' || keymap.hotkey == ''"
                          @click="toggleKeymapEnable(keymap)"></v-switch>
              </template>
            </v-tooltip>
            <v-tooltip text="删除当前模式">
              <template #activator>
                <v-btn icon="mdi-delete-outline" variant="text" width="40" height="40" @click="removeKeymap(keymap.id)"></v-btn>
              </template>
            </v-tooltip>
          </div>
        </td>
      </tr>
    </Table>

    <div class="d-flex justify-end">
      <v-btn class="ma-3" color="green" @click="addKeymap()">新增热键
      </v-btn>
    </div>
  </v-card>
</template>

<style scoped>
.v-text-field >>> input {
  min-height: auto;
  padding: 0 !important;
}

.v-text-field >>> .v-input__details {
  min-height: auto;
  height: 0 !important;
}

.v-switch >>> .v-selection-control {
  min-height: auto;
}

.v-autocomplete >>> .v-field__input {
  padding: 0;
}

.v-autocomplete >>> input {
  top: 13px
}
</style>
