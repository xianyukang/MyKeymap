<template>
  <v-container id="app">
    
    <!-- <v-row v-for="item in config.capslockf" :key="item.name" dense>
      <v-col cols="1">
        <v-chip dark color="green" label><span class="key">{{ item.key }}</span></v-chip>
      </v-col>
      <v-col cols="2">
        <v-chip dark color="green" label ><span class="key">{{ item.key }}</span></v-chip>
        <v-select class="fuck" :items="items" v-model="item.type" label="操作类型"></v-select>
      </v-col>
      <v-col><v-text-field label="激活" v-model="item.value"></v-text-field></v-col>
      <v-col><v-text-field label="或运行" v-model="item.value"></v-text-field></v-col>
    </v-row> -->
    <keyboard @clickKey="keyChanged" :currentKey="currentKey" />
    <action :currentKey="currentKey"/>
  </v-container>
</template>

<script>
import Action from '@/components/Action.vue'
import Keyboard from '../components/Keyboard.vue'
export default {
  name: 'CapslockF',
  created() {},
  methods: {
    keyChanged(key) {
      this.currentKey = key
    },
    firstMappedKey(config) {
      return 'Q'
    }
  },
  data() {
    return {
      currentKey: this.firstMappedKey(this.config),
      keys: 'abcdefghijklmnopqrstuvwxyz,./',
      items: ['启动程序或激活窗口', '发送按键或文本', '鼠标操作', '窗口操作', '执行 ahk 函数'],
    }
  },
  components: { Action, Keyboard },
}
</script>

<style scoped>

</style>