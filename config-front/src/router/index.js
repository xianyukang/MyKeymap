import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import CapslockF from '../views/CapslockF.vue'
import Settings from '../views/Settings.vue'
import CapslockAbbr from '../views/CapslockAbbr.vue'

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
  keymap('Capslock'),
  keymap('CapslockF'),
  keymap('Mode3'),
  keymap('Mode3R'),
  keymap('Mode9'),
  keymap('CapslockSpace'),
  keymap('SpaceMode'),
  keymap('JMode'),
  keymap('Semicolon'),
  keymap('RButtonMode'),
  keymap('LButtonMode'),
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

export default router
