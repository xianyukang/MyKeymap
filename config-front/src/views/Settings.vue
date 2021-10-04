<template>
  <v-container id="app">
    <v-card max-width="790" id="settings-card">
      <v-card-title>各模式开关</v-card-title>
      <v-card-text>
        <v-row>
          <v-col cols="4">
            <v-switch class="switch" width="50" v-model="currConfig()['enableMode3']" label="3 模式"></v-switch>
            <v-switch class="switch" width="50" v-model="currConfig()['enableMode9']" label="9 模式"></v-switch>
            <v-switch class="switch" width="50" v-model="currConfig()['enableJMode']" label="J 模式"></v-switch>
            <v-switch class="switch" width="50" v-model="currConfig()['enableCapslockMode']" label="Capslock"></v-switch>
            <v-switch class="switch" width="50" v-model="currConfig()['enableSemicolonMode']" label="分号模式"></v-switch>
            <v-switch class="switch" width="50" v-model="currConfig()['enableLButtonMode']" label="鼠标左键"></v-switch>
            <v-switch class="switch" width="50" v-model="currConfig()['enableRButtonMode']" label="鼠标右键"></v-switch>
          </v-col>
          <v-col cols="5">
            <v-text-field
              type="number"
              v-model="currConfig()['scrollOnceLineCount']"
              step=".1"
              maxlength="5"
              label="单次滚动的行数"
            ></v-text-field>
            <v-text-field
              type="number"
              v-model="currConfig()['scrollDelay1']"
              step=".1"
              maxlength="5"
              label="进入连续滚动前的延时 (秒)"
            ></v-text-field>
            <v-text-field
              type="number"
              v-model="currConfig()['scrollDelay2']"
              step=".1"
              maxlength="5"
              label="两次滚动的间隔时间 (越小滚动速度越快)"
            ></v-text-field>
          </v-col>
        </v-row>
        <v-row>
          <v-col cols="7">
            <v-switch
              class="switch"
              width="50"
              v-model="currConfig()['runOnStartup']"
              label="开机自启"
              @change="runOnStartup"
            ></v-switch>
            <v-switch
              class="switch"
              width="50"
              v-model="currConfig()['mapRAltToCtrl']"
              label="右 Alt 映射为 Ctrl"
            ></v-switch>
            <v-switch
              class="switch"
              width="50"
              v-model="currConfig()['runAsAdmin']"
              label="管理员权限运行"
              messages=" 某窗口有管理员权限时, MyKeymap 也要有相同的权限才能操作它"
            ></v-switch>
          </v-col>
        </v-row>
      </v-card-text>
    </v-card>
  </v-container>
</template>

<script>
import { escapeFuncString, executeScript } from '../util.js'
export default {
  name: 'Settings',
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
#settings-card {
  margin: 20px;
  margin-top: 70px;
}

#app >>> label {
  margin: 0;
  color: rgba(0, 0, 0, 0.8);
}
</style>