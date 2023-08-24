<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { useFetch } from '@vueuse/core';
import { storeToRefs } from 'pinia';

// TODO: 修改文档和示例
// TODO: 保存时删掉 action 配置中值为空字符串 "" 的字段
// TODO: 修改 ActivateOrRun 函数把 detectHiddenWindow 参数加上
const { action } = storeToRefs(useConfigStore())

function executeScript(arg: string | string[]) {
  let value = ['./MyKeymap.exe', arg]
  if (Array.isArray(arg)) {
    value = ['./MyKeymap.exe', ...arg]
  }
  useFetch('http://localhost:12333/execute').post({
    type: 'run-program',
    value
  })
}

const label1 = "要激活的窗口 (窗口标识符)"
const label2 = "当窗口不存在时要启动的: 程序 / 文件夹 / URL"
const label3 = "命令行参数"
const label4 = "工作目录"
const label5 = "自定义备注"
const label6 = "以管理员身份运行"
const label7 = "检测隐藏窗口"
const label8 = "🔍 查看窗口标识符"
const label9 = "📗 查看例子"

</script>

<template>
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label1" v-model="action.winTitle" />
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label2" v-model="action.target" />
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label3" v-model="action.args" />
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label4" v-model="action.workingDir" />
  <v-text-field color="primary" autocomplete="off" variant="underlined" :label="label5" v-model="action.comment" />
  <v-card-actions class="card-actions">
    <v-checkbox :label="label6" color="secondary" v-model="action.runAsAdmin" />
    <v-checkbox :label="label7" color="secondary" v-model="action.detectHiddenWindow" />
    <v-btn class="action-button" color="primary" variant="outlined" @click="executeScript('bin/WindowSpy.ahk')">{{ label8 }}</v-btn>
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
</style>
