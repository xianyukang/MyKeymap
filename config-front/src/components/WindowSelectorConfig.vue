<template>
  <v-card min-height="700">
    <v-card-title>
      <h3 id="header"></h3>
    </v-card-title>
    <v-card-text style="color: black">
      <!-- <p>
        使用路径变量能缩短路径长度, 比如 <code class="my-code">%Home%\Documents</code> 表示
        <code class="my-code">C:\Users\YourUserName\Documents</code>
      </p> -->

      <v-row>
        <v-col cols="3">
          <div class="th"><h3>应用名</h3></div>
        </v-col>
        <v-col>
          <div class="th"><h3>窗口标识符</h3></div>
        </v-col>
      </v-row>

      <v-row class="row" v-for="(v, index) in $store.state.config.windowSelectors" :key="index">
        <v-col cols="3">
          <v-text-field dense outlined label="" v-model="v.key"></v-text-field>
        </v-col>
        <v-col>
          <v-text-field dense outlined label="" v-model="v.value"></v-text-field>
        </v-col>
      </v-row>
    </v-card-text>
    <v-card-actions>
      <v-spacer></v-spacer>
      <v-btn class="btn" color="green" dark @click="addNewItem"
        >添加一行</v-btn
      >
      <!-- <v-btn class="btn" color="blue" dark @click="$emit('hideDialog')">确认</v-btn> -->
    </v-card-actions>
    <pre style="margin: 10px"></pre>
  </v-card>
</template>

<script>
import _ from 'lodash'

export default {
  emits: ['hideDialog'],
  methods: {
    addNewItem() {
      const selectors = this.$store.state.config.windowSelectors
      const maxItem = _.maxBy(selectors, x => parseInt(x.id))
      const id = maxItem !== undefined ? parseInt(maxItem.id) + 1 : 3
      selectors.push({ id: ''+id, key: '', value: '' })
    }
  },
  data() {
    return {
      key: 'value',
    }
  },
}
</script>

<style scoped>
#header {
  color: rgba(0, 0, 0, 0.7);
}
.th {
  color: rgba(0, 0, 0, 0.8);
  /* border: 1px solid black; */
}
.row {
  margin-bottom: -30px;
}
button.v-btn.btn {
  margin: 0 10px;
  min-width: 102px;
}
code.my-code {
  color: #d05;
  border: solid 1px #ccc;
}
</style>