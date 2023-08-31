// Composables
import Home from '@/views/Home.vue'
import Keymap from '@/views/Keymap.vue'
import { createRouter, createWebHistory } from 'vue-router'
import Settings from "@/views/Settings.vue";
import CustomHotkey from "@/views/CustomHotkey.vue";
import Abbr from "@/views/Abbr.vue";
import HomeSettings from '@/views/HomeSettings.vue';

const routes = [
  {
    path: '/',
    component: () => import('@/layouts/default/Default.vue'),
    children: [
      {
        path: '',
        name: 'Home',
        component: HomeSettings,
      },
      { path: "/keymap/:id(1)", component: CustomHotkey },
      { path: "/keymap/:id(2|3)", component: Abbr },
      { path: "/keymap/:id", component: Keymap },
      { path: "/settings", component: HomeSettings },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
})

export default router
