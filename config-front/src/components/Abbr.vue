<template>
  <v-container>
    <v-row justify="start">
      <v-col cols="auto" v-for="key in Object.keys(currConfig()).sort()" :key="key">
        <v-hover v-slot="{ hover }">
          <v-card
            @click="clickKey(key)"
            :class="hover ? 'my-hover' : ''"
            :height="hover ? 63 : 63"
            :max-width="200"
            :elevation="hover ? 13 : 4"
            :color="keyColor(key, hover).color"
            :dark="keyColor(key, hover).dark"
          >
            <v-card-title
              ><span class="abbr">{{ key }}</span></v-card-title
            >
          </v-card>
        </v-hover>
      </v-col>
      <v-col cols="auto">
        <v-card height="76" width="590" elevation="5">
          <v-card-title>
            <v-row>
              <v-col cols="12">
                <v-text-field
                  id="add-abbr"
                  dense
                  v-model="abbr"
                  @keyup.enter="addAbbr"
                  label="输入ab按回车添加/切换到ab, del ab删除ab, rn cd重命名当前为cd"
                ></v-text-field>
              </v-col>
            </v-row>
          </v-card-title>
        </v-card>
      </v-col>
    </v-row>
  </v-container>
</template>

<script>
function anyKeyExcept(obj, toExclude) {
  for (const [key, value] of Object.entries(obj)) {
    if (key != toExclude) return key
  }
}

export default {
  emits: ['clickKey', 'delKey'],
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
      // if (action.type != '什么也不做' && action.value) return { color: '#98FB98', dark: false }
      return {}
    },
    addAbbr() {
      if (!this.abbr || !this.abbr.trim()) return

      // 删除逻辑
      if (this.abbr.length > 4 && this.abbr.startsWith('del ')) {
        if (Object.keys(this.currConfig()).length > 1) {
          let toDel = this.abbr.substring(4)
          let toFocus = toDel === this.currentKey ? anyKeyExcept(this.currConfig(), this.currentKey) : this.currentKey
          this.$emit('delKey', toDel, toFocus)
        }
        this.abbr = ''
        return
      } 

      // 重命名逻辑
      if (this.abbr.length > 3 && this.abbr.startsWith('rn ')) {
        if (Object.keys(this.currConfig()).length > 1) {
          let newKey = this.abbr.substring(3)
          this.$emit('renameKey', newKey)
        }
        this.abbr = ''
        return
      } 
      
      else if (!this.currConfig()[this.abbr]) {
        let k = this.abbr.replaceAll(' ', '')
        if (!k) return
        console.log('添加', k)

        // note 这里有 bug,  是非响应式属性
        // note Vue 无法检测 property 的添加或移除。由于 Vue 会在初始化实例时对 property 执行 getter/setter 转化，所以 property 必须在 data 对象上存在才能让 Vue 将它转换为响应式的
        // this.currConfig()[k] = {
        //   type: '什么也不做',
        //   value: '',
        // }
        
        // 这样写,  才是响应式属性
        this.$set(this.currConfig(), k, {
          type: '什么也不做',
          value: '',
        })

        this.clickKey(k)
        this.abbr = ''
        return
      }

      this.clickKey(this.abbr)
      this.abbr = ''
    },
  },
  data() {
    return {
      abbr: '',
    }
  },
  computed: {},
}
</script>

<style>
.v-chip {
  /* x偏移量 | y偏移量 | 阴影模糊半径 | 阴影扩散半径 | 阴影颜色 */
  box-shadow: 0px 0px 2px 2px rgba(0, 0, 0, 0.2);
  /* margin: 5px; */
}
.abbr {
  /* border: 2px solid black; */
  font-size: 1.3em;
  font-weight: 400;
  cursor: pointer;
}
.my-hover {
  padding: 1px;
}
#add-abbr {
  font-size: 25px !important;
}
</style>