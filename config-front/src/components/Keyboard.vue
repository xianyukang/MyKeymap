<template>
  <div class="my-container">
    <v-row justify="start" v-for="(line, index) in lines" :key="index">
      <v-col v-for="k in line" :key="k.key" cols="auto">
        <v-hover v-slot="{ hover }">
          <v-card
            @click="clickKey(k.key)"
            class="key"
            :height="hover ? 53 : 53"
            :width="keyWidth(k, hover)"
            :elevation="hover ? 13 : 4"
            :color="keyColor(k, hover).color"
            :dark="keyColor(k, hover).dark"
            :disabled="keyDisabled(k)"
          >
            <v-row class="fill-height" align="center" justify="center" v-text="k.key"></v-row>
          </v-card>
        </v-hover>
      </v-col>
    </v-row>
  </div>
</template>

<script>
import { EMPTY_KEY } from '../util'
export default {
  emits: ['clickKey'],
  methods: {
    reset() {
      this.pressedKey = EMPTY_KEY
    },
    clickKey(key) {
      this.pressedKey = key
      this.$emit('clickKey', key)
    },

    keyDisabled(key) {
      const result = key.disableAt?.includes(this.$route.name)
      return !!result
    },
    keyWidth(key, hover) {
      if (key.key === 'Space') {
        return 150
      }
      return hover ? 54 : 53
    },
    keyColor(keyObj, hover) {
      // if (hover) return { color: '#f3448f', dark: true }
      if (this.keyDisabled(keyObj)) return { color: '#AAA', dark: true }
      if (keyObj.key === this.pressedKey) return { color: 'blue', dark: true }
      const action = this.currConfig()[keyObj.key]['2']
      if (action && action.type != '什么也不做' && action.value) {
        return { color: '#98FB98', dark: false }
      }
      return {}
    },
  },
  computed: {
    lines() {
      const lns = [
        [
          { key: '1', disableAt: [] },
          { key: '2', disableAt: [] },
          { key: '3', disableAt: ['Mode3'] },
          { key: '4', disableAt: [] },
          { key: '5', disableAt: [] },
          { key: '6', disableAt: [] },
          { key: '7', disableAt: [] },
          { key: '8', disableAt: [] },
          { key: '9', disableAt: ['Mode9'] },
          { key: '0', disableAt: [] },
        ],
        [
          { key: 'Q' },
          { key: 'W' },
          { key: 'E' },
          { key: 'R', disableAt: ['Mode3', 'Mode3R'] },
          { key: 'T', disableAt: ['Mode3R'] },
          { key: 'Y', disableAt: [] },
          { key: 'U', disableAt: [] },
          { key: 'I', disableAt: [] },
          { key: 'O', disableAt: ['Mode9'] },
          { key: 'P', disableAt: ['Semicolon'] },
        ],
        [
          { key: 'A' },
          { key: 'S', disableAt: [] },
          { key: 'D' },
          { key: 'F', disableAt: ['Capslock', 'CapslockF', 'Mode3R'] },
          { key: 'G', disableAt: ['Mode3R'] },
          { key: 'H', disableAt: [] },
          { key: 'J', disableAt: ['JMode', 'JModeK', 'JModeL'] },
          { key: 'K', disableAt: ['JMode', 'JModeK', 'JModeL'] },
          { key: 'L', disableAt: ['JMode', 'JModeK', 'JModeL', 'Mode9'] },
          { key: ';', disableAt: ['Semicolon', 'Mode9'] },
        ],
        [
          { key: 'Z', disableAt: ['Mode3R'] },
          { key: 'X', disableAt: ['Mode3R'] },
          { key: 'C', disableAt: ['Mode3R'] },
          { key: 'V', disableAt: ['Mode3R'] },
          { key: 'B', disableAt: [] },
          { key: 'N', disableAt: [] },
          { key: 'M', disableAt: [] },
          { key: ',', disableAt: ['Mode9', 'CommaMode'] },
          { key: '.', disableAt: ['Mode9'] },
          { key: '/', disableAt: ['Semicolon', 'Mode9'] },
        ],
        [{ key: 'Space', disableAt: ['CapslockSpace', 'Capslock', 'SpaceMode'] }],
      ]

      // 请求尚未返回 || 开启了数字键
      const numKeyConfigurable = !this.$store.state.config || this.$store.state.config.Settings.numKeyConfigurable
      if (!numKeyConfigurable) {
        lns.splice(0, 1)
      }

      return lns
    },
  },
  data() {
    return {
      pressedKey: EMPTY_KEY,
    }
  },
}
</script>

<style scoped>
.v-chip {
  /* x偏移量 | y偏移量 | 阴影模糊半径 | 阴影扩散半径 | 阴影颜色 */
  box-shadow: 0px 0px 2px 2px rgba(0, 0, 0, 0.2);
  /* margin: 5px; */
}
.key {
  /* border: 2px solid black; */
  font-size: 1.5em;
  cursor: pointer;
}
</style>