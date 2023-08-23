<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';

const { enabledKeymaps } = storeToRefs(useConfigStore())
const { getKeymapById } = useConfigStore()

const getIcon = (keymap: Keymap) => {
  let icon = "mdi-"
  let hotkey = keymap.parentID != 0 ? getKeymapById(keymap.parentID).hotkey : keymap.hotkey

  // 判断是设置还是自定义热键
  if (hotkey == "settings") {
    return icon + "cog-box"
  } else if (hotkey == "customHotkeys") {
    return icon + "keyboard"
  }

  // 获取首字母
  let key = hotkey.substring(1, 2)
  if (/[LlRr]/.test(key)) {
    key = hotkey.substring(2, 3)
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
  <v-navigation-drawer>
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
      <v-list-item v-for="(keymap, i) in enabledKeymaps" :key="i" :value="keymap"
                   :to="keymap.id < 5 ? '/' + keymap.hotkey : '/keymap/' + keymap.id">
        <template #prepend>
          <v-icon :icon="getIcon(keymap)" size=35></v-icon>
        </template>
        <v-list-item-title>{{ keymap.name }}</v-list-item-title>
      </v-list-item>

    </v-list>

    <v-divider class="border-opacity-25"></v-divider>
  </v-navigation-drawer>
</template>

