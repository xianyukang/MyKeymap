<script setup lang="ts">

import { useConfigStore } from "@/store/config";
import { storeToRefs } from "pinia";
import Action from "@/components/actions/Action.vue";
import Key from "@/components/Key.vue";
import { ref } from "vue";
import trimEnd from "lodash-es/trimEnd";

const { hotkeys } = storeToRefs(useConfigStore())
const { removeHotkey, changeHotkey} = useConfigStore()

const cmd = ref("")

const runCmd = () => {
  let cmdStr = cmd.value.toLowerCase()
  if (!cmdStr || !cmdStr.trim()) {
    return
  }

  if (cmdStr.startsWith("del ")) {
    // 删除
    console.log(cmdStr.substring(4))
    removeHotkey(cmdStr.substring(4))
  } else if (cmdStr.startsWith("rn ")) {
    // 重命名
    cmdStr = cmdStr.substring(3)
    changeHotkey(useConfigStore().hotkey, cmdStr)
  }

  useConfigStore().hotkey = cmdStr.startsWith("del ") ? "" : cmdStr
  cmd.value = ""
}

const formatSpace = (hotkey: string) => {
  const trimmed = trimEnd(hotkey, ' ')
  return trimmed + '◻️'.repeat(hotkey.length - trimmed.length)
}

</script>

<template>
  <v-card class="mb-4 bg-transparent" width="800">
    <v-card-text>
      <v-row justify="start">
        <v-col v-for="(action, hotkey) in hotkeys" cols="auto" :key="hotkey">
          <key :hotkey="hotkey as string" :laber="formatSpace(hotkey as string)"/>
        </v-col>
      </v-row>

      <v-text-field v-model="cmd" @keydown.enter="runCmd()"
                    class="ml-1 mt-5" variant="underlined"
                    label="输入ab按回车添加/切换到ab, del ab删除ab, rn cd重命名当前为cd">
      </v-text-field>
    </v-card-text>
  </v-card>
  <action></action>

</template>

<style scoped>
</style>
