<template>
  <v-container>
    <v-card min-height="630" width="790" elevation="5" class="action-config">
      <v-card-title>
        <v-select
          class="action-select"
          :items="actionTypes"
          v-model="currKey().type"
          outlined
          @change="clearValue"
          :menu-props="{ maxHeight: 900 }"
        ></v-select>
      </v-card-title>
      <v-card-text>
        <template v-if="currKey().type === '启动程序或激活窗口'">
          <v-text-field
            label="要激活的窗口 (选填)"
            v-model="currKey().toActivate"
            @input="activateOrRun"
          ></v-text-field>
          <v-text-field label="窗口不存在时要启动的程序"  v-model="currKey().toRun" @input="activateOrRun"></v-text-field>
          <br>
          <v-text-field label="启动程序的命令行参数 (选填)" dense  v-model="currKey().cmdArgs" @input="activateOrRun"></v-text-field>
          <v-text-field label="启动程序的工作目录 (选填)"  dense v-model="currKey().workingDir" @input="activateOrRun"></v-text-field>
        </template>

        <template v-if="currKey().type === '输入文本或按键'">
          <v-textarea
            auto-grow
            rows="1"
            label="要输入的文本"
            v-model="currKey().textToSend"
            @input="sendKeys"
          ></v-textarea>
          <v-text-field label="然后要输入的按键"  v-model="currKey().keysToSend" @input="sendKeys"></v-text-field>
          <img alt="img" :src="require('../assets/send-keys.png')" /><img />
        </template>

        <template v-if="currKey().type === '执行单行 ahk 代码'">
          <v-text-field label="单行代码 (自定义的函数可以放到 data/custom_functions.ahk)"  v-model="currKey().value"></v-text-field>
          <img alt="img" :src="require('../assets/send-keys.png')" /><img />
        </template>

        <template v-if="currKey().type === '鼠标操作'">
          <v-radio-group v-model="currKey().label" @change="mouseActionChanged">
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

        <template v-if="currKey().type === '窗口操作'">
          <v-radio-group v-model="currKey().value">
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

            <!-- <v-row>
              <v-col>
                <v-radio
                  v-for="action in clickActions"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
              <v-col> </v-col>
            </v-row> -->
          </v-radio-group>
        </template>

        <template v-if="currKey().type === '其他功能'">
          <v-radio-group v-model="currKey().value">
            <v-row>
              <v-col>
                <v-radio
                  v-for="action in otherFeatures1"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
              <v-col>
                <v-radio
                  v-for="action in otherFeatures2"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
            </v-row>

            <br />
            <v-divider></v-divider>
            <br />

            <!-- <v-row>
              <v-col>
                <v-radio
                  v-for="action in clickActions"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
              <v-col> </v-col>
            </v-row> -->
          </v-radio-group>
        </template>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script>
import { escapeFuncString } from '../util'

function toAhkString(s) {
  return s.replaceAll('"', '""')
}

export default {
  created() {},
  props: {
    currentKey: { type: String },
  },
  data() {
    return {
      mouseActions: [
        { label: '鼠标上移', value: '鼠标上移' },
        { label: '鼠标下移', value: '鼠标下移' },
        { label: '鼠标左移', value: '鼠标左移' },
        { label: '鼠标右移', value: '鼠标右移' },
      ],
      scrollActions: [
        { label: '滚轮上滑', value: '滚轮上滑' },
        { label: '滚轮下滑', value: '滚轮下滑' },
        { label: '滚轮左滑', value: '滚轮左滑' },
        { label: '滚轮右滑', value: '滚轮右滑' },
      ],
      clickActions: [
        { label: '鼠标左键', value: '鼠标左键' },
        { label: '鼠标右键', value: '鼠标右键' },
        { label: '鼠标左键按下', value: '鼠标左键按下' },
        { label: '移动鼠标到窗口中心', value: '移动鼠标到窗口中心' },
      ],
      windowActions1: [
        { label: '关闭窗口', value: 'SmartCloseWindow()' },
        { label: '切换到上一个窗口', value: 'send !{tab}' },
        { label: '在当前程序的窗口间切换', value: 'SwitchWindows()' },
        { label: '窗口管理器(EDSF切换、X关闭、空格选择)', value: 'send ^!{tab}' },
        { label: '上一个虚拟桌面', value: 'send {LControl down}{LWin down}{Left}{LWin up}{LControl up}' },
        { label: '下一个虚拟桌面', value: 'send {LControl down}{LWin down}{Right}{LWin up}{LControl up}' },
        { label: '移动窗口到下一个显示器', value: 'send #+{right}' },
      ],
      windowActions2: [
        { label: '窗口最大化', value: 'winmaximize, A' },
        { label: '窗口最小化', value: 'winMinimizeIgnoreDesktop()' },
        { label: '窗口居中(1200x800)', value: 'center_window_to_current_monitor(1200, 800)' },
        { label: '窗口居中(1370x930)', value: 'center_window_to_current_monitor(1370, 930)' },
      ],
      otherFeatures1: [
        { label: '设置字体为红色', value: 'setColor("#D05")' },
        { label: '设置字体为紫色', value: 'setColor("#b309bb")' },
        { label: '设置字体为粉色', value: 'setColor("#FF00FF")' },
        { label: '设置字体为蓝色', value: 'setColor("#2E66FF")' },
        { label: '设置字体为绿色', value: 'setColor("#080")' },
      ],
      otherFeatures2: [
        { label: '滑动关机', value: 'slideToShutdown()' },
        { label: '滑动重启', value: 'slideToReboot()' },
        { label: '打开 MyKeymap 设置', value: 'openSettings()' },
      ],
    }
  },
  methods: {
    sendKeys() {
      this.currKey().prefix = '*'
      const lines = ['']
      if (this.currKey().textToSend) {
        const list = toAhkString(this.currKey().textToSend).split('\n')
        const result = list.map(item => `send % text("${item}")`).join(' "{enter}"\n')
        lines.push(result)
      }
      if (this.currKey().keysToSend) {
        lines.push('send {blind}' + this.currKey().keysToSend)
      }
      lines.push('return')
      this.currKey().value = lines.join('\n')
    },
    activateOrRun() {
      const toActivate = escapeFuncString(this.currKey().toActivate)
      const toRun = escapeFuncString(this.currKey().toRun)
      const cmdArgs = escapeFuncString(this.currKey().cmdArgs)
      const workingDir = escapeFuncString(this.currKey().workingDir)
      // console.log(toActivate, toRun)

      if (!toActivate) {
        this.currKey().toActivate = ''
      }

      this.currKey().value = `
    path = ${toRun}
    ActivateOrRun("${toActivate}", path, "${cmdArgs}", "${workingDir}")
    return`
    },
    // note 当选项发生改变时,  是否要清空掉 value ?
    clearValue() {
      this.currKey().value = ''
      for (const key of Object.keys(this.currKey())) {
        if (!['type', 'value'].includes(key)) {
          delete this.currKey()[key]
        }
      }
      console.log(Object.entries(this.currKey()))
    },
    mouseActionChanged(newValue) {
      console.log('mouseActionChanged')
      let map = {}
      map['鼠标上移'] = ``
      let key = this.currentKey

      map['滚轮上滑'] = `MouseClick, WheelUp, , , 1`
      map['滚轮下滑'] = `MouseClick, WheelDown, , , 1`
      map['滚轮左滑'] = `horizontalScroll("${key}", -1)`
      map['滚轮右滑'] = `horizontalScroll("${key}", 1)`

      map['鼠标上移'] = `fastMoveMouse("${key}", 0, -1)`
      map['鼠标下移'] = `fastMoveMouse("${key}", 0, 1)`
      map['鼠标左移'] = `fastMoveMouse("${key}", -1, 0)`
      map['鼠标右移'] = `fastMoveMouse("${key}", 1, 0)`

      map['鼠标左键'] = `leftClick()`
      map['鼠标右键'] = `rightClick()`
      map['鼠标左键按下'] = `lbuttonDown()`
      map['移动鼠标到窗口中心'] = `centerMouse()`

      if (newValue === '滚轮上滑') this.currKey().prefix = '*'
      if (newValue === '滚轮下滑') this.currKey().prefix = '*'
      if (newValue === '鼠标左键') this.currKey().prefix = '*'
      this.currKey().value = map[newValue] || ''
    },
  },
  computed: {
    actionTypes() {
      if (this.$route.name === 'Capslock')
        return [
          '什么也不做',
          '启动程序或激活窗口',
          '输入文本或按键',
          '鼠标操作',
          '窗口操作',
          '其他功能',
          '执行单行 ahk 代码',
        ]
      else return ['什么也不做', '启动程序或激活窗口', '输入文本或按键', '窗口操作', '其他功能', '执行单行 ahk 代码']
    },
  },
}
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
.action-select .v-select__selection {
  color: black;
  font-size: 1.1em;
}
.action-config .v-text-field {
  margin-left: 10px;
  margin-right: 10px;
}
</style>