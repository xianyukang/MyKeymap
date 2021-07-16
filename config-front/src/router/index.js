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
    component: Capslock,
    props: route => ({
    })
  },
  {
    path: '/capslockf',
    name: 'CapslockF',
    component: CapslockF,
    props: route => ({
    })
  },
  {
    path: '/Mode3',
    name: 'Mode3',
    component: CapslockF,
    props: route => ({
    })
  },
  {
    path: '/Mode9',
    name: 'Mode9',
    component: CapslockF,
    props: route => ({
    })
  },
  {
    path: '/capslockabbr',
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
