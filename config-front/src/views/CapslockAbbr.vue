<template>
  <div class="my-container">
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
    <Abbr @clickKey="keyChanged" @delKey="deleteKey" @renameKey="renameKey" :currentKey="currentKey" />
    <Action :currentKey="currentKey" />
  </div>
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
    deleteKey(toDel, toFocus) {
      console.log(toDel, toFocus)
      this.keyChanged(toFocus)
      delete this.currConfig()[toDel]
    },
    renameKey(newKey) {
      const old = this.currentKey
      this.currConfig()[newKey] = this.currConfig()[old] 
      this.keyChanged(newKey)
      delete this.currConfig()[old]
    },
  },
  data() {
    return {
      currentKey: Object.keys(this.$store.state.config[this.$route.name])[0],
    }
  },
  components: { Action, Abbr },
}
</script>

<style scoped>
</style>