<template>
  <v-app v-if="store.config" class="ml-4">
    <navigation-drawer/>
    <v-main>
        <!--
        因为 settings 页要包含很多输入组件, 所以加载较慢, 每次打开设置页会有小卡顿
        想到的办法是让 settings 页 keep-alive, 不随路由切换而销毁/重新创建
        因为缓存只能加速第二次打开, 首次打开 settings 页还是会卡
        所以把 settings 和 home 合二为一, 在加载首页时悄悄初始化 settings (首页慢 150ms 并不会被用户察觉)
      -->
      <router-view v-slot="{ Component }">
        <keep-alive include="HomeSettings">
          <component :is="Component"/>
        </keep-alive>
      </router-view>
    </v-main>
  </v-app>
</template>

<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import NavigationDrawer from '@/components/NavigationDrawer.vue';
import { onMounted } from "vue";

const store = useConfigStore()

onMounted(() => {
  window.addEventListener("keydown", evt => {
    if (evt.ctrlKey && evt.key.toLowerCase() === 's') {
      evt.preventDefault()
      store.saveConfig()
    }
  })
})
</script>
