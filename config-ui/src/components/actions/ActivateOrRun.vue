<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { server } from '@/store/server';
import { useShortcutStore } from '@/store/shortcut';
import { storeToRefs } from 'pinia';
import { watchEffect } from 'vue';

// TODO: 修改文档和示例
// TODO: 修改 ActivateOrRun 函数把 detectHiddenWindow 参数加上
const { action } = storeToRefs(useConfigStore())
const { shortcuts } = storeToRefs(useShortcutStore())


watchEffect(() => {
  action.value.isEmpty = !action.value.winTitle && !action.value.target
})

const label1 = "要激活的窗口 (窗口标识符)"
const label2 = "当窗口不存在时要启动的: 程序 / 文件夹 / URL"
const label3 = "命令行参数"
const label4 = "工作目录"
const label5 = "自定义备注"
const label6 = "以管理员运行"
const label7 = "检测隐藏窗口"
const label8 = "🔍 查看窗口标识符"
const label9 = "📗 查看例子"
const label10 = "后台运行"

</script>

<template>
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label1" v-model="action.winTitle" />
  <v-combobox class="input"
              color="primary"
              :label="label2"
              :items="shortcuts"
              :hide-no-data="true"
              :menu-props="{ maxHeight: 150 }"
              v-model="action.target"
              variant="underlined"></v-combobox>
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label3" v-model="action.args" />
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label4" v-model="action.workingDir" />
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label5" v-model="action.comment" />
  <v-card-actions class="card-actions">
    <v-checkbox :label="label6" color="secondary" v-model="action.runAsAdmin" />
    <v-checkbox :label="label10" color="secondary" v-model="action.runInBackground" />
    <v-checkbox :label="label7" color="secondary" v-model="action.detectHiddenWindow" />
    <v-btn class="action-button" color="primary" variant="outlined" @click="server.runWindowSpy">{{ label8 }}</v-btn>
    <v-btn class="action-button" color="primary" variant="outlined" target="_blank" href="/ProgramPathExample.html">{{ label9 }}</v-btn>
  </v-card-actions>
</template>

<style scoped>
.card-actions {
  margin-top: -18px;
  margin-left: -18px;
}

.action-button {
  margin-top: -18px;
  margin-right: 17px;
}

.input :deep(i) {
  visibility: hidden;
}
</style>
