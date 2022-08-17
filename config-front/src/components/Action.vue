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

    <v-card min-height="570" :width="cardWidth" elevation="5" class="action-config">
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
              v-model="windowSelector"
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
            label="当窗口不存在时要启动的: 程序路径 / 文件夹 / URL"
            v-model="config.toRun"
            @input="activateOrRun"
          ></v-text-field>
          <v-text-field
            autocomplete="off"
            label="命令行参数"
            v-model="config.cmdArgs"
            @input="activateOrRun"
          ></v-text-field>
          <v-text-field
            autocomplete="off"
            label="工作目录"
            v-model="config.workingDir"
            @input="activateOrRun"
          ></v-text-field>
          <v-text-field
            autocomplete="off"
            label="自定义备注 (按 Caps 输入 help 可回顾配置)"
            v-model="config.comment"
            @input="activateOrRun"
          ></v-text-field>
          <v-card-actions class="card-actions">
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
 Tips: (1) 如果不填窗口标识符就不会尝试激活窗口,  直接启动程序
       (2) 前两个参数至少选填一个、其他参数一般用不到可以不填
       (3) 备注以「 管理员 」开头,  则表示用管理员权限启动程序</pre
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
          <!-- <v-checkbox v-model="config.useSendEvent" color="green" label="使用慢速模式发送按键 (速度慢些, 兼容性好些, 模拟按键不起作用时, 勾上这个试一试)"></v-checkbox> -->
          <pre class="tips">

 Tips: <a target="_blank" href="SendKeyExample.html" style="color: green;">推荐点此查看示例</a>
       </pre>
        </template>

        <template v-if="config.type === '可能会用到的内置函数'">
          <v-text-field
            autocomplete="off"
            label="单行代码"
            v-model="config.value"
          ></v-text-field>
          <v-text-field
            autocomplete="off"
            label="自定义备注"
            v-model="config.comment"
          ></v-text-field>
          <div class="tailwind-scope">
            <table class="w-full text-center text-black">
              <th width="30%">功能</th>
              <th>代码</th>
              <tr>
                <td>窗口居中并设置大小</td>
                <td>center_window_to_current_monitor(1200, 800)</td>
              </tr>
              <tr>
                <td>设置窗口位置、保持默认大小</td>
                <td>set_window_position_and_size(10, 10, "DEFAULT", "DEFAULT")</td>
              </tr>
              <tr>
                <td>以管理员权限运行程序</td>
                <td>run_as_admin("C:\Windows\System32\cmd.exe")</td>
              </tr>
              <tr>
                <td>一次打开多个链接或程序</td>
                <td>launch_multiple("https://baidu.com", "https://bing.com", "cmd.exe")</td>
              </tr>
              <tr>
                <td>进程存在时用热键激活、否则启动程序</td>
                <td>activate_it_by_hotkey_or_run("TIM.exe", "^!z", "D:\TIM.lnk")</td>
              </tr>
              <tr>
                <td>包裹选中的文本</td>
                <td>wrap_selected_text(&quot;&lt;font color='#D05'&gt;{text}&lt;/font&gt;&quot;)</td>
              </tr>
            </table>
          </div>
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
          <pre>
  <font color="blue">当前「 {{ mouseMoveMode }} 」是生效的鼠标移动模式</font>
          </pre>
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
                  <v-radio
                    :label="specialAction.unbindWindow.label"
                    :value="specialAction.unbindWindow.value"
                  ></v-radio>
                </v-radio-group>
              </v-col>

              <v-col> </v-col>
            </v-row>
          </v-radio-group>
        </template>

        <template v-if="config.type === '系统控制'">
          <SystemAction :config="config" />
        </template>
        <template v-if="config.type === '文字处理'">
          <v-radio-group v-model="config.value" @change="onTextActionChanged">
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

              <v-col>
                <v-radio
                  v-for="action in textFeatures3"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>

              <v-col>
                <v-radio
                  v-for="action in textFeatures4"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
            </v-row>
          </v-radio-group>
        </template>
      </v-card-text>
    </v-card>
  </div>
</template>

<script>
import "../action";
import {
  currConfigMixin,
  escapeFuncString,
  executeScript,
  getKeymapName,
  mapKeysToSend,
  notBlank,
  uniqueName,
} from "../util.js";
import { EMPTY_KEY } from "../util";
import _ from "lodash";
import KeyValueConfig from "./KeyValueConfig.vue";
import SystemAction from "./SystemAction.vue";
import WindowSelectorConfig from "./WindowSelectorConfig.vue";
import { windowActions1, windowActions2, specialAction, mouseActions, scrollActions, textFeatures1, textFeatures2, textFeatures3, textFeatures4,clickActions } from "../action";

export default {
  mixins: [currConfigMixin],
  components: { KeyValueConfig, WindowSelectorConfig, SystemAction },
  props: {
    currentKey: { type: String, required: true, },
  },
  data() {
    return {
      showConfigPathVariableDialog: false,
      showWindowSelectorConfig: false,
      windowSelector: "2",
      mouseActions,
      scrollActions,
      clickActions,
      specialAction,
      windowActions1,
      windowActions2,
      textFeatures1,
      textFeatures2,
      textFeatures3,
      textFeatures4,
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
      this.windowSelector = "2";
      this.$store.state.windowSelector = "2"
    },
    onTextActionChanged() {
      if (_.startsWith(this.config.value, 'send') || _.startsWith(this.config.value, 'action_hold_down_shift_key')) {
        this.config.prefix = "*";
      }
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

      // 修复踩到的坑,  javascript 中 `a && b` 的返回值不是 true/false,  
      // 而是 `a` 或 `b`, 当 `a` 为 truthy 时返回 `b`, 当 `a` 为 falsy 时返回 `a`
      let admin = (this.config.comment && this.config.comment.startsWith("管理员")) ? true : false

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
        const adminPart = admin ? `, ${admin}` : ""
        this.config.value = `ActivateOrRun("${toActivate}", "${toRun}", "${cmdArgs}", "${workingDir}"${adminPart})`;
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
      this.$store.state.windowSelector = new_value
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
      map["鼠标左键双击 (选中单词)"] = `myDoubleClick()`;
      map["鼠标左键三击 (选中一行)"] = `myTrippleClick()`;
      map["移动鼠标到窗口中心"] = `centerMouse()`;
      map["让当前窗口进入拖动模式"] = `moveCurrentWindow()`;

      this.config.prefix = "*";
      this.config.value = map[newValue] || "";
      // 只能用一个模式移动鼠标,  比如在 3 模式上配了鼠标操作,  那么 capslock 模式的鼠标操作会失效
      if (this.config.value) {
        this.$store.state.config.Settings.MouseMoveMode = this.$route.name
      }
    },
  },
  computed: {
    cardWidth() {
      if (this.config.type === '文字处理') return 1200 
      if (this.config.type === '可能会用到的内置函数') return 970
      return 790
    },
    mouseMoveMode() {
      return getKeymapName[this.$store.state.config.Settings.MouseMoveMode]
    },
    config() {
      return this.$store.getters.config();
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
        { text: "📚 文字处理", value: "文字处理" },
        { text: "🅰️ 输入文本或按键", value: "输入文本或按键" },
        { text: "🖱️  鼠标操作", value: "鼠标操作" },
        { text: "🏠 窗口操作", value: "窗口操作" },
        { text: "🖥️ 系统控制", value: "系统控制" },
        { text: "⚛️ 可能会用到的内置函数", value: "可能会用到的内置函数" },
      ];

      if (![ 'Capslock', 'CapslockF', 'CapslockSpace', 'Mode3', 'Mode9', 'TabMode', 'Semicolon', 'CommaMode', 'DotMode'].includes(this.$route.name)) {
        const index = result.findIndex(x => x.value === '鼠标操作')
        if (index > 0) {
          result.splice(index, 1);
        }
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

.card-actions {
  margin-top: -6px;
}

.tips {
  margin: 8px 10px -6px 10px;
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
