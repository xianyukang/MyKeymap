import Vue from 'vue'
import Vuex from 'vuex'
import axios from 'axios';


Vue.use(Vuex)

const s = new Vuex.Store({
  state: {
    config: null,
  },
  mutations: {
    SET_CONFIG(state, value) {
      console.log('update config', value)
      state.config = value
    }
  },
  actions: {
    saveConfig(store) {
      axios
        .put('http://localhost:8000/config', store.state.config)
        .then(resp => console.log(resp.data))
    },
    fetchConfig(store) {
      return axios.get('http://localhost:8000/config')
        .then(resp => store.commit('SET_CONFIG', resp.data))
        .catch(error => {
          throw error // 方便后面看堆栈定位问题
        })
    }
  },
  modules: {
  }
})
s.dispatch('fetchConfig')
export default s