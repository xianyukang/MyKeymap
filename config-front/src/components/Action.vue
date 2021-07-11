<template>
  <v-container>
    <v-card height="600" width="720" elevation="5">
      <v-card-title>
        <!-- <h1>{{$store.state.currentKey}}</h1> -->
        <v-row>
          <v-col><v-select :items="actionTypes" v-model="currKey().type" outlined></v-select></v-col>
        </v-row>
      </v-card-title>
      <v-card-text>
        <v-divider></v-divider>
        <v-row>
          <v-col><v-text-field label="要激活的窗口" outlined dense v-model="ActivateOrRun.arg1"></v-text-field></v-col>
        </v-row>
        <v-row>
          <v-col>
            <v-text-field label="窗口不存在时要启动的程序" outlined dense v-model="ActivateOrRun.arg2"> </v-text-field>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script>
export default {
  props: {
    currentKey: { type: String },
    currentConfig: { type: String },
  },
  data() {
    return {
      actionTypes: ['启动程序或激活窗口', '按键重映射为', '鼠标操作', '窗口操作', '执行 ahk 函数', '什么也不做'],
      ActivateOrRun: {
        arg1: '',
        arg2: '',
      },
    }
  },
  methods: {
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
</style>