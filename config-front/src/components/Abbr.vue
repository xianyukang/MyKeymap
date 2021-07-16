<template>
  <v-container>
    <v-row justify="start" >
      <v-col cols="auto" v-for="(value, key) in currConfig()" :key="key">
        <v-hover v-slot="{ hover }">
          <v-card
            @click="clickKey(key)"
            :class="hover ? 'my-hover' : ''"
            :height="hover ? 63 : 63"
            :max-width="100"
            :elevation="hover ? 13 : 4"
            :color="keyColor(key, hover).color"
            :dark="keyColor(key, hover).dark"
          >
          <v-card-title><span class="abbr">{{key}}</span></v-card-title>
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
    keyColor(key, hover) {
      // if (hover) return { color: '#f3448f', dark: true }
      if (key === this.currentKey) return { color: 'blue', dark: true }
      const action = this.currConfig()[key]
      if (action.type != '什么也不做' && action.value) return { color: '#98FB98', dark: false }
      return {}
    },
  },
  data() {
    return {

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
.abbr {
  /* border: 2px solid black; */
  font-size: 1.3em;
  cursor: pointer;
}
.my-hover {
  padding: 1px;
}

</style>