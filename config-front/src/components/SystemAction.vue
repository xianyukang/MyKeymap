<template>
  <v-radio-group v-model="config.label" @change="handleRadioChange">
    <v-row>
      <v-col>
        <v-radio v-for="action in otherFeatures1" :key="action.label" :label="`${action.label}`" :value="action.label"></v-radio>
      </v-col>
      <v-col>
        <v-radio v-for="action in otherFeatures2" :key="action.label" :label="`${action.label}`" :value="action.label"></v-radio>
      </v-col>
    </v-row>

    <br />
    <v-divider></v-divider>
    <br />

    <v-row v-if="config.label === '用指定程序打开选中的文件'">
      <v-col>
        <v-text-field autocomplete="off" label="程序路径" v-model="config.toRun" @input="action_open_selected_with" placeholder="例如 code.exe"></v-text-field>
        <v-text-field autocomplete="off" label="命令行参数 (用 {file} 表示文件路径)" v-model="config.cmdArgs" @input="action_open_selected_with" placeholder=""></v-text-field>
        <v-text-field autocomplete="off" label="自定义备注 (按 Caps 输入 help 可回顾配置)" v-model="config.comment"></v-text-field>
      </v-col>
    </v-row>

    <v-row v-else-if="config.label === '自定义的文件菜单'">
      <v-col>
        <div style="margin-bottom: 8px">
          <a target="_blank" href="CustomShellMenu.html" style="color: green; text-decoration: none">➤ 点此查看介绍, 如果想到了其他实用的菜单项, 也欢迎反馈</a>
        </div>
        <v-textarea v-model="$store.state.config.Settings.CustomShellMenu" autocomplete="off" outlined height="600" hide-details no-resize></v-textarea>
      </v-col>
    </v-row>

    <v-row v-else>
      <v-col>
        <v-radio v-for="action in otherFeatures3" :key="action.label" :label="`${action.label}`" :value="action.label"></v-radio>
      </v-col>
      <v-col>
        <v-radio v-for="action in otherFeatures4" :key="action.label" :label="`${action.label}`" :value="action.label"></v-radio>
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
    group: 1,
    label: "切换「 自动隐藏任务栏 」",
    value: "toggleAutoHideTaskBar()",
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
    label: "自定义的文件菜单",
    value: 'RealShellRun(A_WorkingDir "\\bin\\ahk.exe", """" A_WorkingDir "\\bin\\CustomShellMenu.ahk" """")',
  },
  {
    group: 2,
    label: "复制选中文件的路径",
    value: "action_copy_selected_file_path()",
  },
  {
    group: 2,
    label: "用指定程序打开选中的文件",
    value: "",
  },
  {
    group: 2,
    label: "重启资源管理器",
    value: "restartExplorer()",
  },
  { group: 3, label: "触发缩写功能", value: "enterSemicolonAbbr()" },
  { group: 3, label: "Capslock 命令框", value: "enterCapslockAbbr()" },
  { group: 3, label: "切换 Capslock 状态", value: "toggleCapslock()" },
  { group: 3, label: "锁定当前模式 (然后单键操作)", value: "action_lock_current_mode()", routeNames: [
    "Capslock", "JMode", "Semicolon", "Mode3", "Mode9", "CommaMode", "DotMode", "TabMode", "SpaceMode"
  ] },
  { group: 4, label: "暂停 MyKeymap", value: "\nSuspend, Permit\ntoggleSuspend()\nreturn", routeNames: ["CustomHotkeys"] },
  { group: 4, label: "重启 MyKeymap", value: "\nSuspend, Toggle\nReloadProgram()\nreturn", routeNames: ["CustomHotkeys"] },
  { group: 4, label: "退出 MyKeymap", value: "quit(false)" },
  { group: 4, label: "打开 MyKeymap 设置", value: "openSettings()" },
  { group: 4, label: "回顾 MyKeymap 配置", value: "openHelpHtml()" },
];

import { bindWindow, currConfigMixin, escapeFuncString, executeScript, mapKeysToSend, notBlank } from "../util.js";

function filterByRouteNames(x, routeName) {
  if (!x.routeNames) return true;
  else return x.routeNames.includes(routeName);
}

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
      return actionMap.filter((x) => x.group === 3).filter(x => filterByRouteNames(x, this.$route.name));
    },
    otherFeatures4() {
      return actionMap.filter((x) => x.group === 4).filter(x => filterByRouteNames(x, this.$route.name));
    },
  },
  methods: {
    handleRadioChange() {
      this.config.value = actionMap.find((x) => x.label === this.config.label).value;
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
      cmdArgs = cmdArgs.replace(/{file}/g, `" sel.selected "`);
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