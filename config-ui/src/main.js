import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'
import vuetify from './plugins/vuetify'

// 怎么处理可能存在的 css 类名冲突? 比如 vuetify 和 tailwind 都定义了 .shadow {...}
// 思路(1): 
//     在每个用到了 tailwind css 的组件中, 重新定义用到的原子类:
//     <style scoped src="@/style/tailwind.css"></style>

// 思路(2): 
//     把 tailwind 引入为全局 css,  但让 tailwind 只在 <div class="tailwind-scope">...</div> 这样的元素中起作用
//         ①在 tailwind.config.js 中配置 important: '.tailwind-scope'
//             参考 https://tailwindcss.com/docs/configuration#selector-strategy
//         ②把 preflight 关掉,  因为 Tailwind's base/reset styles 会和 vuetify 冲突
//             参考 https://stackoverflow.com/questions/63761312/how-to-scope-tailwind-css

import '@/style/tailwind.css'

Vue.config.productionTip = false


const vm = new Vue({
  router,
  store,
  vuetify,
  render: h => h(App)
}).$mount('#app')

window.vm = vm
