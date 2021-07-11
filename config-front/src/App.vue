<template>
  <v-app id="inspire">
    <v-navigation-drawer permanent app   id="drawer">
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
            <v-icon :color="item.color">{{ item.icon }}</v-icon>
          </v-list-item-icon>

          <v-list-item-content>
            <v-list-item-title>{{ item.title }}</v-list-item-title>
          </v-list-item-content>
        </v-list-item>
        <v-divider></v-divider>
        <v-btn width="100%" elevation="2" color="primary" @click="$store.dispatch('saveConfig')">
          <v-icon left> mdi-content-save </v-icon> 保存配置</v-btn
        >
      </v-list>
    </v-navigation-drawer>

    <v-main id="main">
      <router-view v-if="config" />
    </v-main>
  </v-app>
</template>

<script>
export default {
  name: 'App',
  created() {},

  data: () => ({
    drawer: true,
    items: [
      { title: 'Capslock', icon: 'mdi-view-dashboard', to: 'Capslock', color: 'green' },
      { title: 'Capslock + F', icon: 'mdi-view-dashboard', to: 'CapslockF', color: 'green' },
      { title: 'Home', icon: 'mdi-image', to: 'Home', color: 'red' },
      { title: '3', icon: 'mdi-numeric-3-box', to: 'Home', color: 'red' },
      { title: '9', icon: 'mdi-numeric-9-box', to: 'Home', color: 'red' },
      { title: '使用说明', icon: 'mdi-help-box', to: 'About', color: 'purple' },
      { title: '关于作者', icon: 'mdi-exclamation-thick', to: 'About', color: 'purple' },
    ],
  }),
}
</script>

<style scoped>
.v-avatar.logo {
  height: 60px !important;
  width: 60px !important;
}
#drawer {
  box-shadow: 0px 0px 1px 1px rgba(0, 0, 0, 0.1);
}
#main {
  background: #f2f3f6;
  background: #FAFAFA;
}
</style>