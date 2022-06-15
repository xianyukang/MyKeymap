<template>
  <v-radio-group v-model="config.label" @change="handleRadioChange">
    <v-row>
      <v-col>
        <v-radio
          v-for="action in otherFeatures1"
          :key="action.label"
          :label="`${action.label}`"
          :value="action.label"
        ></v-radio>
      </v-col>
      <v-col>
        <v-radio
          v-for="action in otherFeatures2"
          :key="action.label"
          :label="`${action.label}`"
          :value="action.label"
        ></v-radio>
      </v-col>
    </v-row>

    <br />
    <v-divider></v-divider>
    <br />

    <v-row v-if="config.label !== '用指定程序打开选中的文件 / 文件夹'">
      <v-col>
        <v-radio
          v-for="action in otherFeatures3"
          :key="action.label"
          :label="`${action.label}`"
          :value="action.label"
        ></v-radio>
      </v-col>
      <v-col>
        <v-radio
          v-for="action in otherFeatures4"
          :key="action.label"
          :label="`${action.label}`"
          :value="action.label"
        ></v-radio>
      </v-col>
    </v-row>
    <v-row v-else>
      <v-col>
        <v-text-field
          autocomplete="off"
          label="程序路径"
          v-model="config.toRun"
          @input="action_open_selected_with"
          placeholder="例如 code.exe"
        ></v-text-field>
        <v-text-field
          autocomplete="off"
          label="启动程序的命令行参数 (用 %selected% 表示选中文件的路径)"
          v-model="config.cmdArgs"
          @input="action_open_selected_with"
          placeholder="例如 %selected%"
        ></v-text-field>
        <v-text-field
          autocomplete="off"
          label="自定义备注 (按 Caps 输入 help 可回顾配置)"
          v-model="config.comment"
        ></v-text-field>
      </v-col>
    </v-row>
  </v-radio-group>
</template>

<script>
const actionMap = [
  {
    group: 1,
    label: "锁屏",
    value: "SystemLockScreen()",
  },
  {
    group: 1,
    label: "睡眠",
    value: 'DllCall("PowrProf\\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)',
  },
  {
    group: 1,
    label: "关机",
    value: "slideToShutdown()",
  },
  {
    group: 1,
    label: "重启",
    value: "slideToReboot()",
  },
  {
    group: 1,
    label: "音量调节",
    value: `MyRun("SoundControl.exe")`,
  },
  {
    group: 1,
    label: "显示器亮度调节",
    value: "run, bin\\ahk.exe bin\\changeBrightness.ahk",
  },
  {
    group: 2,
    label: "打开「 回收站 」",
    value: "run, shell:RecycleBinFolder",
  },
  {
    group: 2,
    label: "打开「 下载 」文件夹",
    value: "run, shell:downloads",
  },
  {
    group: 2,
    label: "复制选中文件的路径",
    value: "action_copy_selected_file_path()",
  },
  {
    group: 2,
    label: "用指定程序打开选中的文件 / 文件夹",
    value: "",
  },
  {
    group: 3,
    label: "重启资源管理器",
    value: "restartExplorer()",
  },
  {
    group: 3,
    label: "切换「 自动隐藏任务栏 」",
    value: "toggleAutoHideTaskBar()",
  },
  { group: 3, label: "缩写功能", value: "enterSemicolonAbbr()" },
  { group: 3, label: "Capslock 指令框", value: "enterCapslockAbbr()" },
  { group: 3, label: "切换 Capslock 状态", value: "toggleCapslock()" },
  { group: 4, label: "暂停 MyKeymap", value: "\nSuspend, Permit\ntoggleSuspend()\nreturn" },
  { group: 4, label: "重启 MyKeymap", value: "\nSuspend, Toggle\nReloadProgram()\nreturn" },
  { group: 4, label: "退出 MyKeymap", value: "quit(false)" },
  { group: 4, label: "打开 MyKeymap 设置", value: "openSettings()" },
  { group: 4, label: "回顾 MyKeymap 配置", value: "openHelpHtml()" },
];

import {
  bindWindow,
  currConfigMixin,
  escapeFuncString,
  executeScript,
  mapKeysToSend,
  notBlank,
} from "../util.js";
export default {
  props: ["config"],
  data() {
    return {};
  },

  computed: {
    otherFeatures1() {
      return actionMap.filter((x) => x.group === 1);
    },
    otherFeatures2() {
      return actionMap.filter((x) => x.group === 2);
    },
    otherFeatures3() {
      return actionMap.filter((x) => x.group === 3);
    },
    otherFeatures4() {
      const res = actionMap.filter((x) => x.group === 4);
      if (this.$store.state.selectedKey.includes(" Up")) {
        return res;
      } else {
        return res;
      }
    },
  },
  methods: {
    handleRadioChange() {
      this.config.value = actionMap.find(
        (x) => x.label === this.config.label
      ).value;
    },
    action_open_selected_with() {
      let toRun = escapeFuncString(this.config.toRun);
      let cmdArgs = escapeFuncString(this.config.cmdArgs);

      // 用路径变量替换路径
      for (const item of this.$store.state.config.pathVariables) {
        if (item.key && item.value) {
          const re = new RegExp(`%${item.key}%`, "g");
          if (toRun) {
            toRun = toRun.replace(re, item.value);
          }
        }
      }
      toRun = toRun.replace(/%(\w+)%/g, `" $1 "`);
      cmdArgs = cmdArgs.replace(/%selected%/g, `" sel.selected "`);
      cmdArgs = cmdArgs.replace(/%current%/g, `" sel.current "`);
      cmdArgs = cmdArgs.replace(/%filename%/g, `" sel.filename "`);
      cmdArgs = cmdArgs.replace(/%purename%/g, `" sel.purename "`);

      if (notBlank(toRun) && notBlank(cmdArgs)) {
        // action_open_selected_with("" A_Programs "\Visual Studio Code\Visual Studio Code.lnk", "-fuck" Explorer_GetSelection() "")
        // 把 %A_Programs% 改成 " A_Programs "
        this.config.value = `sel := Explorer_GetSelection(), action_open_selected_with("${toRun}", "${cmdArgs}")`;
      }
    },
  },
};
</script>

<style>
</style>