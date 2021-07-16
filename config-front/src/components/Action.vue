<template>
  <v-container>
    <v-card height="600" width="720" elevation="5">
      <v-card-title>
        <v-select :items="actionTypes" v-model="currKey().type" outlined @change="clearValue"></v-select>
      </v-card-title>
      <v-card-text>
        <template v-if="currKey().type === '启动程序或激活窗口'">
          <v-text-field label="要激活的窗口" outlined v-model="currKey().toActivate" @input="activateOrRun"></v-text-field>
          <v-text-field label="窗口不存在时要启动的程序" outlined v-model="currKey().toRun" @input="activateOrRun">
          </v-text-field>
        </template>

        <template v-if="currKey().type === '鼠标操作'">
          <v-radio-group v-model="currKey().value">
            <v-row>
              <v-col>
                <v-radio
                  v-for="action in mouseActions"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
              <v-col>
                <v-radio
                  v-for="action in scrollActions"
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
                <v-radio
                  v-for="action in clickActions"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
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

            <v-row>
              <v-col>
                <v-radio
                  v-for="action in clickActions"
                  :key="action.label"
                  :label="`${action.label}`"
                  :value="action.value"
                ></v-radio>
              </v-col>
              <v-col> </v-col>
            </v-row>
          </v-radio-group>
        </template>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script>
import { escapeFuncString } from '../util'
export default {
  created () {},
  props: {
    currentKey: { type: String },
  },
  data() {
    return {
      actionTypes: ['启动程序或激活窗口', '按键重映射为', '鼠标操作', '窗口操作', '执行 ahk 函数', '什么也不做'],
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
        { label: '上一个虚拟桌面', value: 'send  {LControl down}{LWin down}{Left}{LWin up}{LControl up}' },
        { label: '下一个虚拟桌面', value: 'send {LControl down}{LWin down}{Right}{LWin up}{LControl up}' },
        { label: '移动窗口到下一个显示器', value: 'send #+{right}' },
      ],
      windowActions2: [
        { label: '窗口最大化', value: 'winmaximize, A' },
        { label: '窗口最小化', value: 'winminimize, A' },
        { label: '窗口居中(1200x800)', value: 'center_window_to_current_monitor(1200, 800)' },
        { label: '窗口居中(1370x930)', value: 'center_window_to_current_monitor(1370, 930)' },
      ],
    }
  },
  methods: {
    activateOrRun() {
      const toActivate = escapeFuncString(this.currKey().toActivate)
      const toRun = escapeFuncString(this.currKey().toRun)
      // console.log(toActivate, toRun)
      this.currKey().value = `ActivateOrRun("${toActivate}", "${toRun}")`
    },
    // note 当选项发生改变时,  是否要清空掉 value ?
    clearValue() {
      this.currKey().value = ''
    },
  },
  computed: {},
}
</script>

<style>
/* 需要去掉 scoped 属性才能让 css 作用于 vuetify 的组件 */
label.v-label.v-label--active {
  font-size: 1.2em;
  color: darkmagenta;
}
div.v-radio label.v-label {
  color: black;
}
div.v-radio.v-item--active label.v-label {
  color: red;
  font-size: 1.1em;
}
</style>