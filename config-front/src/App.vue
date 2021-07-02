<template>
  <v-app id="inspire">
    <v-navigation-drawer permanent app>
      <v-list-item>
        <v-list-item-content>
          <v-list-item-title class="text-h6"> MyKeymap </v-list-item-title>
          <v-list-item-subtitle> subtext </v-list-item-subtitle>
        </v-list-item-content>
      </v-list-item>

      <v-divider></v-divider>

      <v-list nav>
        <v-list-item v-for="item in items" :key="item.title" :to="{name: item.to}">
          <v-list-item-icon>
            <v-icon>{{ item.icon }}</v-icon>
          </v-list-item-icon>

          <v-list-item-content>
            <v-list-item-title>{{ item.title }}</v-list-item-title>
          </v-list-item-content>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>


    <v-main>
      <router-view />
    </v-main>
  </v-app>
</template>

<script>
export default {
  name: 'App',

  data: () => ({
    drawer: true,
    items: [
      { title: 'Capslock', icon: 'mdi-view-dashboard', to: 'Capslock' },
      { title: 'Home', icon: 'mdi-image', to: 'Home' },
      { title: 'About', icon: 'mdi-help-box', to: 'About' },
    ],
  }),
}
</script>
