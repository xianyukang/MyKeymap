import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import CapslockF from '../views/CapslockF.vue'
import Settings from '../views/Settings.vue'
import CapslockAbbr from '../views/CapslockAbbr.vue'
import { ALL_KEYMAPS, EMPTY_KEY } from '../util.js'

import store from '../store/index.js'

Vue.use(VueRouter)

function keymap(name) {
  return {
    path: '/' + name,
    name: name,
    component: CapslockF,
    props: route => ({
    })
  }
}

const keymaps = ALL_KEYMAPS.map(x => keymap(x))

const routes = [
  {
    path: '/',
    redirect: { name: 'Capslock' },
  },
  {
    path: '/home',
    name: 'Home',
    component: Home,
  },
  ...keymaps,
  {
    path: '/Settings',
    name: 'Settings',
    component: Settings,
    props: route => ({
    })
  },
  {
    path: '/SemicolonAbbr',
    name: 'SemicolonAbbr',
    component: CapslockAbbr,
    props: route => ({
    })
  },
  {
    path: '/CapslockAbbr',
    name: 'CapslockAbbr',
    component: CapslockAbbr,
    props: route => ({
    })
  },
  {
    path: '/about',
    name: 'About',
    // route level code-splitting
    // this generates a separate chunk (about.[hash].js) for this route
    // which is lazy-loaded when the route is visited.
    component: () => import(/* webpackChunkName: "about" */ '../views/About.vue')
  }
]

const router = new VueRouter({
  routes
})

router.beforeEach((to, from, next) => {
  store.state.routeName = to.name
  store.state.windowSelector = '2'
  store.state.selectedKey = EMPTY_KEY
  next()
})


export default router
