<template>
  <v-app id="inspire">
    <v-navigation-drawer app id="drawer">
      <v-list-item>
        <v-list-item-avatar rounded="0" class="logo">
          <v-img alt="img" :src="require('./assets/logo.png')"></v-img>
        </v-list-item-avatar>
        <v-list-item-content>
          <v-list-item-title class="text-h4"> MyKeymap </v-list-item-title>
        </v-list-item-content>
      </v-list-item>

      <v-divider></v-divider>

      <v-list nav>
        <v-list-item v-for="item in items" :key="item.title" :to="{ name: item.to }">
          <v-list-item-icon>
            <v-icon class="nav-tab-icon" :color="item.color">{{ item.icon }}</v-icon>
          </v-list-item-icon>

          <v-list-item-content>
            <v-list-item-title>{{ item.title }}</v-list-item-title>
          </v-list-item-content>
        </v-list-item>
        <v-divider></v-divider>
        <v-btn width="100%" elevation="2" color="primary" @click="saveConfig">
          <v-icon left> mdi-content-save </v-icon> 保存配置 (ctrl+s)</v-btn
        >
      </v-list>
    </v-navigation-drawer>

    <v-main id="main">
      <router-view v-if="config" />
    </v-main>

    <v-snackbar v-model="$store.state.snackbar" color="green" timeout="1500" min-width="600" height="70"  outlined>
      <span id="snackBarText">{{ $store.state.snackbarText }}</span>
      <template v-slot:action="{ attrs }">
        <v-btn color="black" text v-bind="attrs" @click="snackbar = false"> </v-btn>
      </template>
    </v-snackbar>
  </v-app>
</template>

<script>
import hotkeys from 'hotkeys-js'

// By default hotkeys are not enabled for INPUT SELECT TEXTAREA elements.
hotkeys.filter = function (event) {
  return true
}

export default {
  name: 'App',
  created() {
    hotkeys('ctrl+s', (event, handler) => {
      event.preventDefault() // Prevent the default refresh event under WINDOWS system
      this.saveConfig()
    })
  },

  data: () => ({
    drawer: true,
    items: [
      { title: 'Capslock', icon: 'mdi-triangle', to: 'Capslock', color: 'green' },
      { title: 'Capslock + F', icon: 'mdi-triangle', to: 'CapslockF', color: 'green' },
      { title: 'Capslock 缩写', icon: 'mdi-triangle', to: 'CapslockAbbr', color: 'green' },
      { title: 'J 模式', icon: 'mdi-circle', to: 'JMode', color: 'blue' },
      { title: '; 分号模式', icon: 'mdi-circle', to: 'Semicolon', color: 'blue' },
      { title: '; 分号缩写', icon: 'mdi-circle', to: 'SemicolonAbbr', color: 'blue' },
      { title: '3 模式', icon: 'mdi-numeric-3-box', to: 'Mode3', color: 'red' },
      { title: '3 + R 模式', icon: 'mdi-numeric-3-box', to: 'Mode3R', color: 'red' },
      { title: '9 模式', icon: 'mdi-numeric-9-box', to: 'Mode9', color: 'red' },
      { title: '使用说明', icon: 'mdi-help-box', to: 'About', color: 'purple' },
      { title: '关于作者', icon: 'mdi-exclamation-thick', to: 'About', color: 'purple' },
    ],
  }),
  methods: {
    saveConfig() {
      this.$store.dispatch('saveConfig')
    },
  },

  computed: {},
}
</script>

<style>
.v-avatar.logo {
  height: 60px !important;
  width: 60px !important;
}
#drawer {
  box-shadow: 0px 0px 1px 1px rgba(0, 0, 0, 0.1);
}
#main {
  background: #f2f3f6;
  background: #fafafa;
}

.nav-tab-icon {
  font-size: 26px !important;
}
#snackBarText {
  /* color: black; */
  font-size: 1.4em;
  padding-left: 115px;
}
</style>