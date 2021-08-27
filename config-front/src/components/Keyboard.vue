<template>
  <v-container>
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
  </v-container>
</template>

<script>
export default {
  emits: ['clickKey'],
  props: {
    currentKey: { type: String },
  },
  methods: {
    clickKey(key) {
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
      if (keyObj.disableAt?.includes(this.$route.name)) return { color: '#AAA', dark: true }
      if (keyObj.key === this.currentKey) return { color: 'blue', dark: true }
      const action = this.currConfig()[keyObj.key]
      if (action) {
        if (action.type != '什么也不做' && action.value) return { color: '#98FB98', dark: false }
      }
      return {}
    },
  },
  data() {
    return {
      lines: [
        [
          { key: 'Q', disabled: false, used: false },
          { key: 'W', disabled: false, used: true, activated: true },
          { key: 'E', disabled: false, used: true },
          { key: 'R', disabled: false, used: true, disableAt: ['Mode3', 'Mode3R']},
          { key: 'T', disabled: false, used: true, disableAt: ['CapslockF', 'Mode3R'] },
          { key: 'Y', disabled: false, used: true, disableAt: ['JMode'] },
          { key: 'U', disabled: false, used: true, disableAt: ['JMode'] },
          { key: 'I', disabled: false, used: true, disableAt: [] },
          { key: 'O', disabled: false, used: true, disableAt: ['Mode9'] },
          { key: 'P', disabled: false, used: true, disableAt: ['Semicolon', 'Mode9'] },
        ],
        [
          { key: 'A', disabled: false, used: false },
          { key: 'S', disabled: false, used: true, disableAt: ['Mode3'] },
          { key: 'D', disabled: false, used: true },
          { key: 'F', disabled: false, used: true, disableAt: ['Capslock', 'CapslockF', 'Mode3R']},
          { key: 'G', disabled: false, used: true, disableAt: ['CapslockF', 'Mode3', 'Mode3R'] },
          { key: 'H', disabled: false, used: true, disableAt: ['JMode', 'Mode9'] },
          { key: 'J', disabled: false, used: true, disableAt: ['JMode', 'Mode9']},
          { key: 'K', disabled: false, used: true, disableAt: ['JMode', 'Mode9'] },
          { key: 'L', disabled: false, used: true, disableAt: ['JMode', 'Mode9'] },
          { key: ';', disabled: false, used: true, disableAt: ['Semicolon', 'Mode9'] },
        ],
        [
          { key: 'Z', disabled: false, used: false, disableAt: ['Capslock', 'Mode3', 'Mode3R'] },
          { key: 'X', disabled: false, used: true, disableAt: ['CapslockF', 'Mode3', 'Mode3R'] },
          { key: 'C', disabled: false, used: false, disableAt: ['CapslockF', 'Mode3', 'Mode3R'] },
          { key: 'V', disabled: false, used: false, disableAt: ['CapslockF', 'Mode3', 'Mode3R'] },
          { key: 'B', disabled: false, used: true, disableAt: ['JMode', 'Mode9'] },
          { key: 'N', disabled: false, used: true, disableAt: ['JMode', 'Mode9'] },
          { key: 'M', disabled: false, used: true, disableAt: ['JMode', 'Mode9'] },
          { key: ',', disabled: false, used: true, disableAt: ['Semicolon', 'Mode9'] },
          { key: '.', disabled: false, used: true, disableAt: ['Semicolon', 'Mode9'] },
          { key: '/', disabled: false, used: true, disableAt: ['Semicolon', 'Mode9'] },
        ],
        [
          { key: 'Space', disabled: false, used: false },
        ],
      ],
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