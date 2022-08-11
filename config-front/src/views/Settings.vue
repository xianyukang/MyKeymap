<template>
  <div class="my-container">
    <v-row>
      <v-col cols="6">
        <v-card height="420" min-width="410" class="settings-card">
          <v-card-title>各模式开关</v-card-title>
          <v-card-text>
            <v-row>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableMode3']" label="3 模式"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableMode9']" label="9 模式"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableJMode']" label="J 模式"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableSemicolonMode']" label="分号模式"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableCapslockMode']" label="Caps 模式"></v-switch>
              </v-col>
              <!-- <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableCapslockAbbr']" label="Caps 指令"></v-switch>
              </v-col> -->
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableCapsF']" label="Caps + F"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableCapsSpace']" label="Caps+Space"></v-switch>
              </v-col>
              <!-- <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableLButtonMode']" label="鼠标左键"></v-switch>
              </v-col> -->
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableRButtonMode']" label="鼠标右键"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableSpaceMode']" label="空格模式"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableTabMode']" label="Tab 模式"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableCommaMode']" label="逗号模式"></v-switch>
              </v-col>
              <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableDotMode']" label="句号模式"></v-switch>
              </v-col>
              <!-- <v-col cols="3">
                <v-switch class="switch" v-model="currConfig()['enableCustomHotkeys']" label="自定义热键"></v-switch>
              </v-col> -->
            </v-row>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col lg="5">
        <v-card min-height="320" max-width="450" class="settings-card">
          <v-card-title>其他设置</v-card-title>
          <v-card-text>
            <v-switch
              class="switch"
              v-model="currConfig()['runOnStartup']"
              label="开机自启"
              @change="runOnStartup"
              messages="可能需要关掉再开启才能生效"
            ></v-switch>
            <!-- <v-switch class="switch" v-model="currConfig()['mapRAltToCtrl']" label="右 Alt 映射为 Ctrl"></v-switch> -->
            <!-- <v-switch class="switch" v-model="currConfig()['numKeyConfigurable']" label="让主键区上方的数字键可自定义"></v-switch> -->
            <v-switch
              class="switch"
              v-model="currConfig()['runAsAdmin']"
              label="管理员权限运行"
              messages="某窗口有管理员权限时, MyKeymap也要有相同的权限才能操作它"
            ></v-switch>
            <v-switch
              class="switch"
              v-model="currConfig()['exitMouseModeAfterClick']"
              label="用键盘点击鼠标后退出键盘移动鼠标"
            ></v-switch>
            <v-switch
              class="switch"
              v-model="currConfig()['showMouseMovePrompt']"
              label="提示目前正在用键盘移动鼠标️"
            ></v-switch>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
    <v-row>
      <v-col cols="4">
        <v-card class="settings-card">
          <v-card-title>按键重映射</v-card-title>
          <v-card-text style="padding-bottom: 0;">
            <pre style="color: black;">
<a target="_blank" href="https://wyagd001.github.io/zh-cn/docs/KeyList.htm#keyboard" style="color: green; text-decoration: none">键名可以查阅此处</a>, 如果想把右 Alt 重映射为左 Ctrl 键:
①在下面添加一行 <code style="color: #d05; border: 1px solid #ddd; padding: 1px 6px;">RAlt::LCtrl</code> 就行  ②删掉对应的行则取消映射
          </pre>
          <v-textarea v-model="currConfig()['KeyMapping']" autocomplete="off" outlined ></v-textarea>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="3">
        <v-card class="settings-card">
          <v-card-title>滚轮滑动参数</v-card-title>
          <v-card-text>
            <v-text-field
              type="number"
              v-model="currConfig()['scrollOnceLineCount']"
              step="1"
              maxlength="5"
              label="单次滚动的行数"
            ></v-text-field>
            <v-text-field
              type="number"
              v-model="currConfig()['scrollDelay1']"
              step=".01"
              maxlength="5"
              label="进入连续滚动前的延时 (秒)"
            ></v-text-field>
            <v-text-field
              type="number"
              v-model="currConfig()['scrollDelay2']"
              step=".01"
              maxlength="5"
              label="两次滚动的间隔时间 (越小滚动速度越快)"
            ></v-text-field>
          </v-card-text>
        </v-card>
      </v-col>
      <v-col cols="auto">
        <v-card class="settings-card">
          <v-card-title>鼠标移动参数</v-card-title>
          <v-card-text>
            <v-row>
              <v-col>
                <v-text-field
                  type="number"
                  v-model="currConfig()['moveDelay1']"
                  step=".01"
                  maxlength="5"
                  label="进入连续移动前的延时(秒)"
                ></v-text-field
              ></v-col>
              <v-col>
                <v-text-field
                  type="number"
                  v-model="currConfig()['moveDelay2']"
                  step=".01"
                  maxlength="5"
                  label="两次移动的间隔时间(秒)"
                ></v-text-field
              ></v-col>
            </v-row>
            <v-row>
              <v-col>
                <v-text-field
                  type="number"
                  v-model="currConfig()['fastMoveRepeat']"
                  step="1"
                  maxlength="5"
                  label="快速模式步长 (像素)"
                ></v-text-field
              ></v-col>
              <v-col
                ><v-text-field
                  type="number"
                  v-model="currConfig()['fastMoveSingle']"
                  step="1"
                  maxlength="5"
                  label="快速模式首步长 (像素)"
                ></v-text-field
              ></v-col>
            </v-row>
            <v-row>
              <v-col>
                <v-text-field
                  type="number"
                  v-model="currConfig()['slowMoveRepeat']"
                  step="1"
                  maxlength="5"
                  label="慢速模式步长 (像素)"
                ></v-text-field
              ></v-col>
              <v-col>
                <v-text-field
                  type="number"
                  v-model="currConfig()['slowMoveSingle']"
                  step="1"
                  maxlength="5"
                  label="慢速模式首步长 (像素)"
                ></v-text-field
              ></v-col>
            </v-row>
          </v-card-text>
        </v-card>
      </v-col>
    </v-row>
  </div>
</template>

<script>
import { currConfigMixin, escapeFuncString, executeScript } from '../util.js'
export default {
  name: 'Settings',
  mixins: [currConfigMixin],
  created() {
    // console.log(this.currConfig())
  },
  methods: {
    runOnStartup() {
      if (this.currConfig()['runOnStartup']) {
        executeScript(['bin/other.ahk', 'enableRunOnStartup'])
      } else {
        executeScript(['bin/other.ahk', 'disableRunOnStartup'])
      }
    },
  },
  data() {
    return {}
  },
}
</script>

<style scoped>
.settings-card {
  margin: 20px;
  /* margin-top: 70px; */
}

.my-container >>> label {
  margin: 0;
  color: black;
}
</style>