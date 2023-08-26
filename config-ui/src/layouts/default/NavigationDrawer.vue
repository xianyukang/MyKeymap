<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';

const { enabledKeymaps } = storeToRefs(useConfigStore())
const { getKeymapById, saveConfig } = useConfigStore()

const getIcon = (keymap: Keymap) => {
  let icon = "mdi-"
  let hotkey = keymap.parentID ? getKeymapById(keymap.parentID).hotkey : keymap.hotkey

  // 判断是设置还是自定义热键
  if (hotkey == "settings") {
    return icon + "cog-box"
  } else if (hotkey == "customHotkeys") {
    return icon + "keyboard"
  }

  // 去除热键中的符号
  hotkey = hotkey.replace(/^[^!#^+\w]/, '')
  // 获取首字母
  let key = hotkey.substring(0, 1)
  if (/[LlRr]/.test(key)) {
    key = hotkey.substring(1, 2)
  }
  key = key.toLowerCase()

  // 首字母不为热键修复符或字母
  if (/[^#!^+a-z0-9]/.test(key)) {
    return icon + "rhombus"
  }

  if (/\d/.test(key)) {
    return icon + "numeric-" + key + "-box"
  }

  if (key == "!") {
    key = "a"
  } else if (key == "#") {
    key = "w"
  } else if (key == "^") {
    key = "c"
  } else if (key == "+") {
    key = "s"
  }

  return icon + "alpha-" + key + "-box"
}

</script>

<template>
  <v-navigation-drawer :permanent="true">
    <v-list-item>
      <template #prepend>
        <v-avatar size="70">
          <v-img src="@/assets/logo.png"></v-img>
        </v-avatar>
      </template>

      <v-list-item-title class=" font-size-1.6em font-500 h-1.2em">MyKeymap</v-list-item-title>
      <v-list-item-subtitle>version: 2.0.0</v-list-item-subtitle>
    </v-list-item>

    <v-divider class="border-opacity-25"></v-divider>

    <v-list>
      <v-virtual-scroll :items="enabledKeymaps" height="calc(100vh - 158px)">
        <template #default="{ item: keymap, index }">
          <v-list-item :key="index" :value="keymap"
                       :to="keymap.id != 4 ? '/keymap/' + keymap.id : '/' + keymap.hotkey">
            <template #prepend>
              <v-icon :icon="getIcon(keymap)" size=35></v-icon>
            </template>
            <v-list-item-title>{{ keymap.name }}</v-list-item-title>
          </v-list-item>
        </template>
      </v-virtual-scroll>
    </v-list>

    <v-divider class="border-opacity-25"></v-divider>
    <v-btn class="ma-3" width="90%" color="blue" prepend-icon="mdi-content-save-outline" variant="outlined" @click="saveConfig">
      保存配置（CTRL+S）
    </v-btn>
  </v-navigation-drawer>
</template>

