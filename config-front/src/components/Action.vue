<template>
  <div class="my-container">
    <v-dialog
      v-model="showConfigPathVariableDialog"
      overlay-opacity="0.30"
      max-width="1080"
      @click:outside="
        showConfigPathVariableDialog = !showConfigPathVariableDialog
      "
    >
      <key-value-config @hideDialog="showConfigPathVariableDialog = false" />
    </v-dialog>

    <v-dialog
      persistent
      v-model="showWindowSelectorConfig"
      overlay-opacity="0.30"
      max-width="1080"
      @click:outside="hideWindowSelectorConfig"
    >
      <window-selector-config />
    </v-dialog>

    <v-card min-height="570" width="790" elevation="5" class="action-config">
      <v-card-title style="padding-bottom: 0">
        <v-row>
          <v-col cols="5">
            <v-select
              outlined
              class="action-select"
              :menu-props="{ maxHeight: 900 }"
              :disabled="disableSelectBox"
              :items="windowSelectors"
              item-text="key"
              item-value="id"
              v-model="$store.state.windowSelector"
              @change="handleWindowSelectorChange"
            ></v-select>
          </v-col>
          <v-col cols="7">
            <v-select
              class="action-select"
              :items="actionTypes"
              v-model="config.type"
              outlined
              @change="clearConfig"
              :menu-props="{ maxHeight: 900 }"
              :disabled="disableSelectBox"
            ></v-select>
          </v-col>
        </v-row>
      </v-card-title>
      <v-card-text>
        <template v-if="config.type === '启动程序或激活窗口'">
          <v-text-field
            autocomplete="off"
            label="要激活的窗口 (窗口标识符)"
            v-model="config.toActivate"
            @input="activateOrRun"
          ></v-text-field>
          <v-text-field
            autocomplete="off"
            label="窗口不存在时要启动的: 程序路径 / 文件夹 / URL"
            v-model="config.toRun"
            @input="activateOrRun"
          ></v-text-field>
          <v-text-field
            autocomplete="off"
            label="启动程序的命令行参数"
            v-model="config.cmdArgs"
            @input="activateOrRun"
          ></v-text-field>
          <v-text-field
            autocomplete="off"
            label="启动程序的工作目录"
            v-model="config.workingDir"
            @input="activateOrRun"
          ></v-text-field>
          <v-text-field
            autocomplete="off"
            label="自定义备注 (按 Caps 输入 help 可回顾配置)"
            v-model="config.comment"
            @input="activateOrRun"
          ></v-text-field>
          <v-card-actions>
            <v-btn
              class="action-button"
              color="purple"
              dark
              outlined
              @click="execute('bin/WindowSpy.ahk')"
              >🔍 查看窗口标识符</v-btn
            >
            <v-btn
              class="action-button"
              color="purple"
              dark
              outlined
              target="_blank"
              href="/ProgramPathExample.html"
              >📗 查看例子</v-btn
            >
            <v-btn
              class="action-button"
              color="purple"
              dark
              outlined
              @click="configPathVariable"
              >⚙️配置路径变量</v-btn
            >
          </v-card-actions>

          <pre class="tips">
 Tips: (1) 如果不填窗口标识符就不会尝试激活窗口,  直接启动程序.
       (2) 前两个参数至少选填一个,  其他参数可以不填
       (3) 含有空格的路径要用双引号包起来, 例如 "D:\空    格"</pre
          >
        </template>

        <template v-if="config.type === '输入文本或按键'">
          <v-textarea
            auto-grow
            rows="1"
            label="要输入的按键或文本"
            v-model="config.keysToSend"
            @input="action_send_keys"
          ></v-textarea>
          <v-text-field
            autocomplete="off"
            label="自定义备注 (按 Caps 输入 help 可回顾配置)"
            v-model="config.comment"
          ></v-text-field>
          <pre class="tips">

 Tips: (1) <a target="_blank" href="SendKeyExample.html" style="color: green;">点此查看发送按键或文本的示例</a>
       (2) 输入按键 abc 会受输入法中英文状态的影响,  输入文本 abc 则不会
       (3) 所以想发送文本 abc 时,  建议给文本加 {text} 前缀, 比如 {text}abc</pre>
        </template>

        <template v-if="config.type === '执行单行 ahk 代码'">
          <v-text-field
            autocomplete="off"
            label="单行代码 (自定义的函数可以放到 data/custom_functions.ahk)"
            v-model="config.value"
          ></v-text-field>
        </template>

        <template v-if="config.type === '鼠标操作'">
          <v-radio-group v-model="config.label" @change="mouseActionChanged">
            <v-row>
              <v-col>
                <v-radio
                  v-for="action in mouseActions"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.label"
                ></v-radio>
              </v-col>
              <v-col>
                <v-radio
                  v-for="action in scrollActions"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.label"
                ></v-radio>
              </v-col>
            </v-row>

            <br />
            <v-divider></v-divider>
            <br />

            <v-row>
              <v-col>
                <v-radio
                  v-for="action in clickActions"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.label"
                ></v-radio>
              </v-col>
              <v-col> </v-col>
            </v-row>
          </v-radio-group>
        </template>

        <template v-if="config.type === '窗口操作'">
          <v-radio-group v-model="config.value">
            <v-row>
              <v-col>
                <v-radio
                  v-for="action in windowActions1"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
              <v-col>
                <v-radio
                  v-for="action in windowActions2"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
            </v-row>

            <br />
            <v-divider></v-divider>
            <br />

            <v-row>
              <v-col>
                <v-radio-group v-model="config.value">
                  <v-radio
                    :label="specialAction.bindWindowToCurrentKey.label"
                    :value="specialAction.bindWindowToCurrentKey.generateValue(this.$route.name, this.currentKey)"
                  ></v-radio>
                </v-radio-group>
              </v-col>

              <v-col> </v-col>
            </v-row>
          </v-radio-group>
        </template>

        <template v-if="config.type === '系统控制'">
          <ExplorerAction :config="config" />
        </template>
        <template v-if="config.type === '文字处理'">
          <v-radio-group v-model="config.value">
            <v-row>
              <v-col>
                <v-radio
                  v-for="action in textFeatures1"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
              <v-col>
                <v-radio
                  v-for="action in textFeatures2"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
            </v-row>

            <br />
            <v-divider></v-divider>
            <br />
          </v-radio-group>
        </template>
      </v-card-text>
    </v-card>
  </div>
</template>

<script>
import Vue from "vue";
import "../action";
import {
  bindWindow,
  currConfigMixin,
  escapeFuncString,
  executeScript,
  mapKeysToSend,
  notBlank,
  uniqueName,
} from "../util.js";
import { host, EMPTY_KEY } from "../util";
import _ from "lodash";
import KeyValueConfig from "./KeyValueConfig.vue";
import ExplorerAction from "./SystemAction.vue";
import WindowSelectorConfig from "./WindowSelectorConfig.vue";
import { windowActions1, windowActions2, specialAction, mouseActions, scrollActions, textFeatures1, textFeatures2, clickActions } from "../action";

export default {
  mixins: [currConfigMixin],
  components: { KeyValueConfig, WindowSelectorConfig, ExplorerAction },
  created() {},
  props: {
    currentKey: { type: String },
  },
  watch: {},
  data() {
    return {
      showConfigPathVariableDialog: false,
      showWindowSelectorConfig: false,
      mouseActions,
      scrollActions,
      clickActions,
      specialAction,
      windowActions1,
      windowActions2,
      textFeatures1,
      textFeatures2,
    };
  },
  methods: {
    execute(arg) {
      executeScript(arg);
    },
    configPathVariable() {
      this.showConfigPathVariableDialog = true;
    },
    hideWindowSelectorConfig() {
      this.showWindowSelectorConfig = false;
      this.$store.state.windowSelector = "2";
    },
    action_send_keys() {
      this.config.prefix = "*";
      this.config.value = "";
      delete this.config["send_key_function"];
      const keysToSend = this.config.keysToSend;

      if (!keysToSend) {
        return;
      }

      const lines = keysToSend
        .split("\n")
        .filter((x) => x && _.trim(x).length > 0)
        .map((x) => mapKeysToSend(x));

      if (lines.length == 1) {
        this.config.value = lines[0].trimStart();
        return;
      }

      const prefix = this.$route.name + this.$store.state.windowSelector;
      const funcName = uniqueName(prefix, this.currentKey);

      const result = [`${funcName}() {`];
      result.push(lines.join("\n"));
      result.push("}");

      this.config.send_key_function = result.join("\n");
      this.config.value = `${funcName}()`;
    },
    activateOrRun() {
      let toActivate = escapeFuncString(this.config.toActivate);
      let toRun = escapeFuncString(this.config.toRun);
      let cmdArgs = escapeFuncString(this.config.cmdArgs);
      let workingDir = escapeFuncString(this.config.workingDir);

      if (!toActivate) {
        this.config.toActivate = "";
      }

      // 用路径变量替换路径
      for (const item of this.$store.state.config.pathVariables) {
        if (item.key && item.value) {
          const re = new RegExp(`%${item.key}%`, "g");
          if (toRun) {
            toRun = toRun.replace(re, item.value);
          }
          if (cmdArgs) {
            cmdArgs = cmdArgs.replace(re, item.value);
          }
          if (workingDir) {
            workingDir = workingDir.replace(re, item.value);
          }
        }
      }

      toRun = toRun.replace(/%(\w+)%/g, `" $1 "`);
      workingDir = workingDir.replace(/%(\w+)%/g, `" $1 "`);

      if (notBlank(toRun) || notBlank(toActivate)) {
        this.config.value = `ActivateOrRun("${toActivate}", "${toRun}", "${cmdArgs}", "${workingDir}")`;
      } else {
        this.config.value = "";
      }
    },
    clearConfig() {
      this.config.value = "";
      for (const key of Object.keys(this.config)) {
        if (key === "type" || key === "value") {
          // skip
        } else {
          delete this.config[key];
        }
      }
    },
    handleWindowSelectorChange(new_value) {
      if (new_value === "1") {
        this.showWindowSelectorConfig = true;
        return;
      }
    },
    mouseActionChanged(newValue) {
      console.log("mouseActionChanged");
      let map = {};
      map["鼠标上移"] = ``;
      let key = this.currentKey;

      map["滚轮上滑"] = `scrollWheel("${key}", 1)`;
      map["滚轮下滑"] = `scrollWheel("${key}", 2)`;
      map["滚轮左滑"] = `scrollWheel("${key}", 3)`;
      map["滚轮右滑"] = `scrollWheel("${key}", 4)`;

      map["鼠标上移"] = `fastMoveMouse("${key}", 0, -1)`;
      map["鼠标下移"] = `fastMoveMouse("${key}", 0, 1)`;
      map["鼠标左移"] = `fastMoveMouse("${key}", -1, 0)`;
      map["鼠标右移"] = `fastMoveMouse("${key}", 1, 0)`;

      map["鼠标左键"] = `leftClick()`;
      map["鼠标右键"] = `rightClick()`;
      map["鼠标左键按下"] = `lbuttonDown()`;
      map["移动鼠标到窗口中心"] = `centerMouse()`;
      map["让当前窗口进入拖动模式"] = `moveCurrentWindow()`;

      this.config.prefix = "*";
      this.config.value = map[newValue] || "";
    },
  },
  computed: {
    config() {
      // 返回当前选中的键关联的配置
      if (this.currentKey === EMPTY_KEY) {
        return { type: "什么也不做", value: "" };
      }

      let sel = this.$store.state.windowSelector;
      if (sel === "1") {
        sel = "2";
      }

      if (!this.currConfig()[this.currentKey][sel]) {
        Vue.set(this.currConfig()[this.currentKey], sel, {
          type: "什么也不做",
          value: "",
        });
      }

      return this.currConfig()[this.currentKey][sel];
    },
    windowSelectors() {
      const config = this.$store.state.config;
      const selectors = [
        { id: "1", key: "🛠️ 点此添加应用", value: "USELESS" },
        { id: "2", key: "🌎 全局生效", value: "USELESS" },
      ];

      if (config && config.windowSelectors) {
        return [...selectors, ...config.windowSelectors].filter((x) => x.value);
      }

      return selectors;
    },
    actionTypes() {
      const result = [
        { text: "⛔ 什么也不做", value: "什么也不做" },
        { text: "👾 启动程序或激活窗口", value: "启动程序或激活窗口" },
        { text: "🅰️ 输入文本或按键", value: "输入文本或按键" },
        { text: "🖱️  鼠标操作", value: "鼠标操作" },
        { text: "🏠 窗口操作", value: "窗口操作" },
        { text: "🖥️ 系统控制", value: "系统控制" },
        { text: "📚 文字处理", value: "文字处理" },
        { text: "⚛️ 执行单行 ahk 代码", value: "执行单行 ahk 代码" },
      ];
      if (this.$route.name !== "Capslock") {
        result.splice(3, 1);
      }
      return result;
    },
    disableSelectBox() {
      return this.currentKey === EMPTY_KEY;
    },
  },
};
</script>

<style>
/* 需要去掉 scoped 属性才能让 css 作用于 vuetify 的组件 */
label.v-label.v-label--active {
  top: 2px;
  font-size: 1.15em;
  color: darkmagenta;
}
div.v-radio label.v-label {
  color: black;
}
div.v-radio.v-item--active label.v-label {
  color: red;
  font-size: 1.1em;
}
#single-line-code-hint {
  margin-top: -20px;
  color: orangered;
}
.tips {
  margin: 10px;
  color: black;
}
.action-select .v-select__selection {
  /* color: black; */
  /* font-size: 1.1em; */
}
.action-config .v-text-field {
  margin-left: 10px;
  margin-right: 10px;
}
.action-button {
  margin-right: 17px;
}
</style>
