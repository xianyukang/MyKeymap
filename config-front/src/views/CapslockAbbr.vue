<template>
  <v-container id="app">
    
    <!-- <v-row v-for="item in config.capslockf" :key="item.name" dense>
      <v-col cols="1">
        <v-chip dark color="green" label><span class="key">{{ item.key }}</span></v-chip>
      </v-col>
      <v-col cols="2">
        <v-chip dark color="green" label ><span class="key">{{ item.key }}</span></v-chip>
        <v-select class="fuck" :items="items" v-model="item.type" label="操作类型"></v-select>
      </v-col>
      <v-col><v-text-field label="激活" v-model="item.value"></v-text-field></v-col>
      <v-col><v-text-field label="或运行" v-model="item.value"></v-text-field></v-col>
    </v-row> -->
    <Abbr @clickKey="keyChanged" :currentKey="currentKey" :currentConfig="currentConfig"/>
    <Action :currentKey="currentKey" :currentConfig="currentConfig"/>
  </v-container>
</template>

<script>
import Action from '@/components/Action.vue'
import Abbr from '../components/Abbr.vue'
export default {
  name: 'CapslockAbbr',
  created() {},
  methods: {
    keyChanged(key) {
      this.currentKey = key
    },
    firstMappedKey(config) {
      return 'sd'
    }
  },
  data() {
    return {
      currentKey: this.firstMappedKey(this.config),
      currentConfig: 'capslockabbr',
    }
  },
  components: { Action, Abbr },
}
</script>

<style scoped>

</style>