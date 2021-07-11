import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import vuetify from './plugins/vuetify'

Vue.config.productionTip = false
Vue.mixin({
  methods: {
    currKey() {
      return this.config[this.$store.state.currentConfig][this.currentKey]
    },
    currConfig() {
      return this.config[this.$store.state.currentConfig]
    },
  },
  computed: {
    config() {
      return this.$store.state.config
    }
  },
})

const vm = new Vue({
  router,
  store,
  vuetify,
  render: h => h(App)
}).$mount('#app')

window.vm = vm
