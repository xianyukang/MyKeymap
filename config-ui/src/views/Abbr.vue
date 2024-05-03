<script setup lang="ts">

import { useConfigStore } from "@/store/config";
import { storeToRefs } from "pinia";
import Action from "@/components/actions/Action.vue";
import Key from "@/components/Key.vue";
import { ref } from "vue";
import trimEnd from "lodash-es/trimEnd";
import ActionCommentTable from "@/components/ActionCommentTable.vue";

const { hotkeys } = storeToRefs(useConfigStore())
const { removeHotkey, changeHotkey, translate } = useConfigStore()

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
  <div class="d-flex flex-wrap mt-4">
    <div>
      <v-card class="mb-4 bg-transparent" width="800">
        <v-card-text>
          <v-row justify="start">
            <v-col v-for="(action, hotkey) in hotkeys" cols="auto" :key="hotkey">
              <key :hotkey="hotkey as string" :label="formatSpace(hotkey as string)"/>
            </v-col>
          </v-row>

          <v-text-field v-model="cmd" @keydown.enter="runCmd()"
                        class="ml-1 mt-5" variant="underlined" color="primary"
                        :label="translate('label:406')">
          </v-text-field>
        </v-card-text>
      </v-card>
      <action></action>
    </div>
    <action-comment-table class="ml-14 mr-4" style="min-width: 200px; flex: 1">
      <template #keyText="{hotkey}">
        {{ formatSpace(hotkey as string) }}
      </template>
    </action-comment-table>
  </div>

</template>

<style scoped>
</style>
