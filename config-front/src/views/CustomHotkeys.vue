<template>
  <div class="tailwind-scope">
    <div class="flex flex-row ml-3 mt-2">
      <div>
        <v-card class="w-96 overflow-x-hidden">
          <Table>
            <!-- 表格头 -->
            <template #thead>
              <th class="pl-6 py-3 text-left text-xs font-bold text-blue-500 uppercase tracking-wider">热键</th>
              <th class="pl-6 py-3 text-left text-xs font-bold text-blue-500 uppercase tracking-wider">备注</th>
            </template>
            <template #tbody>
              <!-- 表格行 -->
              <tr
                v-for="item in sortedCustomHotkeys"
                :key="item.key"
                @click="handleClick(item.key)"
                class="hover:cursor-pointer"
                :class="currentKey == item.key ? 'bg-blue-100' : ''"
              >
                <!-- 单元格 -->
                <TableCell :cell-value="item.key" @changed="handleChange(item.key, $event.value)" />
                <TableCell :cell-value="item.comment" :readonly="true" />
              </tr>
            </template>
          </Table>
          <v-card-actions>
            <v-spacer></v-spacer>
            <v-btn class="btn" color="green" dark @click="handleAdd">添加一行</v-btn>
            <v-btn class="btn" color="black" dark @click="handleDelete">删除选中行</v-btn>
          </v-card-actions>
        </v-card>
      </div>
      <div class="">
        <div class="flex flex-row">
          <v-card class="w-60 ml-5">
            <v-card-title>简述</v-card-title>
            <v-card-text class="">
              <pre class="text-gray-700">
如果想设置 Alt + C 这样的热键:
(1) 点击添加一行
(2) 在热键那一列里填 !c


(英文感叹号 ! 用于表示 Alt 键
</pre
              >
            </v-card-text>
          </v-card>
          <v-card class="w-60 ml-5">
            <v-card-title>例子1</v-card-title>
            <v-card-text class="">
              <pre class="text-gray-700">
!c   表示  Alt + C
#c   表示  Win + C
^c   表示  Ctrl + C
^!c  表示  Ctrl + Alt + C
^+c  表示  Ctrl + Shift + C
+!c  表示  Shift + Alt + C
</pre
              >
            </v-card-text>
          </v-card>
          <v-card class="w-60 ml-5">
            <v-card-title>例子2</v-card-title>
            <v-card-text class="">
              <pre class="text-gray-700">
F11    表示  F11
!F2    表示  Alt + F2
+F2    表示  Shift + F2
+space 表示  Shift + 空格

(更多例子可以去群里问
</pre
              >
            </v-card-text>
          </v-card>
        </div>
        <Action :currentKey="currentKey" />
      </div>
    </div>
  </div>
</template>

<script>
import Vue from "vue";
import Action from "../components/Action.vue";
import { EMPTY_KEY } from "../util.js";
import Table from "../components/table/Table.vue";
import TableCell from "../components/table/TableCell.vue";
import { getLabelByValue } from "../action";

function toComment(config) {
  if (!config) return "什么也不做";
  config = config["2"]; // 以全局配置为准
  if (!config) return "";
  if (config.type == "什么也不做") return "什么也不做";
  if (config.comment) return config.comment;
  if (getLabelByValue[config.value]) return getLabelByValue[config.value];
  if (config.label) return config.label;

  if (config.type === "启动程序或激活窗口") {
    return "启动某个程序 (缺备注)";
  }

  if (config.type === "输入文本或按键" && config.keysToSend) {
    if (config.keysToSend.includes("\n")) return "输入 " + config.keysToSend.split("\n")[0] + "...";
    else return "输入 " + config.keysToSend;
  }

  if (config.value.startsWith("bindOrActivate(")) {
    return "绑定活动窗口到这个键";
  }

  return config.value;
}

export default {
  name: "CustomHotkeys",
  components: { Table, TableCell, Action },
  data() {
    return {
      currentKey: EMPTY_KEY, // 组件的创建时的默认 key 是 EMPTY_KEY
      keys: "abcdefghijklmnopqrstuvwxyz,./",
      items: ["启动程序或激活窗口", "输入文本或按键", "鼠标操作", "窗口操作", "可能会用到的内置函数"],
      people: [
        { id: 1, name: "!'", email: "重启 MyKeymap" },
        { id: 2, name: "+!'", email: "暂停 MyKeymap" },
        { id: 3, name: "#c", email: "Win + C" },
        { id: 4, name: "+capslock", email: "切换大小写" },
        { id: 5, name: "!capslock", email: "切换大小写" },
      ],
    };
  },
  computed: {
    sortedCustomHotkeys() {
      const list = Object.entries(this.$store.state.config.CustomHotkeys).map(([k, v]) => ({
        key: k,
        comment: toComment(v),
      }));
      list.sort((a, b) => (a.comment < b.comment ? -1 : 1));
      return list;
    },
  },
  methods: {
    toComment: toComment,
    handleChange(key, newKey) {
      Vue.set(this.$store.state.config.CustomHotkeys, newKey, this.$store.state.config.CustomHotkeys[key]);
      this.handleClick(newKey); // 让 currentKey 和 selectedKey 切换到 newKey
      Vue.delete(this.$store.state.config.CustomHotkeys, key);
    },
    handleAdd() {
      Vue.set(this.$store.state.config.CustomHotkeys, "点此修改", undefined);
    },
    handleDelete() {
      const key = this.currentKey;
      this.currentKey = EMPTY_KEY;
      this.$store.state.selectedKey = EMPTY_KEY;
      Vue.delete(this.$store.state.config.CustomHotkeys, key);
    },
    handleClick(key) {
      this.currentKey = key;
      this.$store.state.selectedKey = key;
    },
  },
};
</script>

<style scoped>
</style>