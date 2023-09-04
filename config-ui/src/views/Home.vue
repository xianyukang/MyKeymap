<script lang="ts" setup>


const font1 = "/font-compare/1.png"
const font2 = "/font-compare/2.png"
const font3 = "/font-compare/3.png"
const font4 = "/font-compare/4.png"
const font5 = "/font-compare/5.png"
const font6 = "/font-compare/6.png"

</script>

<template>
  <v-container>
    <v-row>
      <v-col>
        <div class="text-h5">欢迎</div>
        <div>1.文档施工中...</div>
      </v-col>
    </v-row>
    <v-row>
      <v-col>
        <div class="text-h5">字体</div>
        <div>1. 可以美化浏览器字体，因为字体文件占几十 M 所以不打包在 MyKeymap 里面</div>
        <div>2. 效果对比:
          「 <a target="_blank" :href="font1">修改前</a> / <a target="_blank" :href="font2">修改后</a> 」，
          「 <a target="_blank" :href="font3">修改前</a> / <a target="_blank" :href="font4">修改后</a> 」，
          「 <a target="_blank" :href="font5">修改前</a> / <a target="_blank" :href="font6">修改后</a> 」</div>
        <div>3. 如何修改:
          ①<a target="_blank" href="https://www.bilibili.com/video/BV1pP4y187bR/">去这下载工具</a>
          ②把其中的常用字体全部装上
          ③<a target="_blank" href="https://www.bilibili.com/video/BV1pP4y187bR?t=190.0">从这跟着视频</a>一步一步操作 </div>
      </v-col>
    </v-row>
  </v-container>
</template>

<style scoped>
.text-h5 {
  color: #4169e1;
  font-weight: bold;
}

a {
  text-decoration: none;
  color: green;
}

a:hover {
  color: purple;
}
</style>
