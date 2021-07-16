<template>
  <v-container id="app" fluid>
    <v-simple-table dense>
      <template v-slot:default>
        <thead>
          <tr>
            <th class="text-left" style="width: 4%"> </th>
            <th class="text-left" style="width: 13%"> </th>
            <th class="text-left"> </th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in currConfig()" :key="item.name">
            <td
              ><v-chip dark color="green" label
                ><span class="key">{{ item.key }}</span></v-chip
              ></td
            >
            <td><v-select class="fuck" dense :items="items" v-model="item.type"></v-select></td>
            <td><v-text-field v-model="item.value"></v-text-field></td>
          </tr>
        </tbody>
      </template>
    </v-simple-table>
  </v-container>
</template>

<script>
export default {
  name: 'Capslock',
  created() { },
  methods: { },
  data() {
    return {
      keys: 'abcdefghijklmnopqrstuvwxyz,./',
      items: ['启动程序或激活窗口', '按键重映射为', '鼠标操作', '窗口操作', '执行 ahk 函数'],
    }
  },
  components: {},
}
</script>

<style scoped>
.v-chip {
  /* x偏移量 | y偏移量 | 阴影模糊半径 | 阴影扩散半径 | 阴影颜色 */
  box-shadow: 0px 0px 2px 2px rgba(0, 0, 0, 0.2);
}
.v-chip span {
  font-size: 1.3em;
}
.v-text-field {
  font-size: 0.75em;
}

table * {
  margin-top: -9px;
  margin-bottom: -9px;
}
</style>