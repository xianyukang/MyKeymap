<template>
  <div class="my-container">
    <keyboard ref="kb" @clickKey="currentKey = $event" />
    <action :currentKey="currentKey"/>
  </div>
</template>

<script>
import Action from '@/components/Action.vue'
import Keyboard from '../components/Keyboard.vue'
import { EMPTY_KEY } from '../util.js'
export default {
  name: 'CapslockF',
  beforeRouteLeave(to, from, next) {
    // note 两个路由共用一个组件时,  可能需要重置组件状态
    this.currentKey = EMPTY_KEY // 路由变化前,  重置当前 key 
    this.$refs.kb.reset()       // 重置键盘按下的键
    next();
  },
  data() {
    return {
      currentKey: EMPTY_KEY,  // 组件的创建时的默认 key 是 EMPTY_KEY
      keys: 'abcdefghijklmnopqrstuvwxyz,./',
      items: ['启动程序或激活窗口', '输入文本或按键', '鼠标操作', '窗口操作', '执行单行 ahk 代码'],
    }
  },
  components: { Action, Keyboard },
}
</script>

<style scoped>
</style>