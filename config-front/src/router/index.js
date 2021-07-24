import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
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
    path: '/Capslock',
    name: 'Capslock',
    component: CapslockF,
    props: route => ({
    })
  },
  {
    path: '/CapslockF',
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
    path: '/Mode3R',
    name: 'Mode3R',
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
    path: '/JMode',
    name: 'JMode',
    component: CapslockF,
    props: route => ({
    })
  },
  {
    path: '/Semicolon',
    name: 'Semicolon',
    component: CapslockF,
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
