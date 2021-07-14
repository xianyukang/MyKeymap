import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import Capslock from '../views/Capslock.vue'
import CapslockF from '../views/CapslockF.vue'
import CapslockAbbr from '../views/CapslockAbbr.vue'

Vue.use(VueRouter)

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
  {
    path: '/capslock',
    name: 'Capslock',
    component: Capslock
  },
  {
    path: '/capslock-f',
    name: 'CapslockF',
    component: CapslockF
  },
  {
    path: '/capslock-abbr',
    name: 'CapslockAbbr',
    component: CapslockAbbr
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
