import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import Capslock from '../views/Capslock.vue'

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
