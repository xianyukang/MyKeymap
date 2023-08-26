// Composables
import Home from '@/views/Home.vue'
import Keymap from '@/views/Keymap.vue'
import { createRouter, createWebHistory } from 'vue-router'
import Settings from "@/views/Settings.vue";
import CustomHotkey from "@/views/CustomHotkey.vue";

const routes = [
  {
    path: '/',
    component: () => import('@/layouts/default/Default.vue'),
    children: [
      {
        path: '',
        name: 'Home',
        component: Home,
      },
      { path: "/keymap/:id(1)", component: CustomHotkey },
      { path: "/keymap/:id(2|3)", component: Home },
      { path: "/keymap/:id", component: Keymap },
      { path: "/settings", component: Settings },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes,
})

export default router
