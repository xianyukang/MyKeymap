<template>
  <v-container id="app" fluid>
    <!-- <v-row>
      <v-col>按键</v-col>
      <v-col>操作类型</v-col>
      <v-col>xxx</v-col>
    </v-row>
    <v-row>
      <v-col>按键</v-col>
      <v-col> <v-select :items="items"></v-select></v-col>
      <v-col>xxx</v-col>
    </v-row> -->
    <v-simple-table dense>
      <template v-slot:default>
        <thead>
          <tr>
            <th class="text-left" style="width: 10%">  </th>
            <th class="text-left" style="width: 22%">  </th>
            <th class="text-left">  </th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in maps" :key="item.name">
            <td><v-chip dark color="primary" label ><span class="key">{{ item.key }}</span></v-chip></td>
            <td><v-select :items="items" v-model="item.type"></v-select></td>
            <td><v-text-field v-model="item.value"></v-text-field></td>
          </tr>
        </tbody>
      </template>
    </v-simple-table>
    [
    <!-- <div v-for="k in keys" :key="k">
      { key: '{{ k }}', type: '执行 AutoHotkey 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\OneNote
      for Windows 10.lnk")' },
    </div> -->
    ]
  </v-container>
</template>

<script>
export default {
  name: 'Capslock',
  data() {
    return {
      keys: 'abcdefghijklmnopqrstuvwxyz,./',
      items: ['重映射为', '执行 ahk 脚本', '鼠标操作', '窗口操作', ],
      desserts: [
        {
          name: 'Frozen Yogurt',
          calories: 159,
        },
        {
          name: 'Ice cream sandwich',
          calories: 237,
        },
        {
          name: 'Eclair',
          calories: 262,
        },
        {
          name: 'Cupcake',
          calories: 305,
        },
        {
          name: 'Gingerbread',
          calories: 356,
        },
        {
          name: 'Jelly bean',
          calories: 375,
        },
        {
          name: 'Lollipop',
          calories: 392,
        },
        {
          name: 'Honeycomb',
          calories: 408,
        },
        {
          name: 'Donut',
          calories: 452,
        },
        {
          name: 'KitKat',
          calories: 518,
        },
      ],
      maps: [
{ key: 'a', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'b', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'c', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'd', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'e', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'f', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'g', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'h', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'i', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'j', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'k', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'l', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'm', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'n', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'o', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'p', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'q', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'r', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 's', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 't', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'u', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'v', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'w', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'x', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'y', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: 'z', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: ',', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: '.', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
{ key: '/', type: '执行 ahk 脚本', value: 'ActivateOrRun("OneNote for Windows 10", "shortcuts\\OneNote for Windows 10.lnk")' },
],
    }
  },
  components: {},
}
</script>

<style scoped>
.key {
  font-size: 1.3em;
}
.v-text-field {
  font-size: 0.75em;
}
</style>