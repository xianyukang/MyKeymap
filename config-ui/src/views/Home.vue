<script lang="ts" setup>
import { useFetch } from '@vueuse/core'
const url = 'http://localhost:12333/config'
const { isFetching, data, error } = useFetch(url)

</script>

<template>
  <div v-if="error" style="color: red;">{{ error }}</div>
  <div v-else-if="isFetching">loading...</div>
  <div v-else>{{ data }}</div>
</template>