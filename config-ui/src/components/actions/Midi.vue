<script lang="ts" setup>
import { useConfigStore } from '@/store/config';
import { storeToRefs } from 'pinia';
import { computed, watchEffect } from 'vue';

const { action } = storeToRefs(useConfigStore())
const { translate } = useConfigStore()

// 音符号 n -> 音名[n % 12] + 八度 (floor(n / 12) - 1), 例如 60 -> C4
const noteNames = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
const noteName = (n: number) => noteNames[n % 12] + (Math.floor(n / 12) - 1)

const noteItems = Array.from({ length: 128 }, (_, n) => ({ title: noteName(n), value: n }))
const channelItems = Array.from({ length: 16 }, (_, i) => i + 1)

// 音符号: 未设置时留空提示选择, 不主动写回
const note = computed<number | undefined>({
  get: () => action.value.midiNote,
  set: (v: number | undefined) => {
    action.value.midiNote = v
    // 首次选择音符号时补齐通道/力度默认值, 避免后端收到 0
    if (v != null) {
      if (action.value.midiChannel == null) action.value.midiChannel = 1
      if (action.value.midiVelocity == null) action.value.midiVelocity = 100
    }
  },
})

// 通道/力度: 本地兜底显示默认值, 仅在用户交互后才写回
const channel = computed({
  get: () => action.value.midiChannel ?? 1,
  set: (v: number) => { action.value.midiChannel = v },
})

const velocity = computed({
  get: () => action.value.midiVelocity ?? 100,
  set: (v: number) => { action.value.midiVelocity = v },
})

watchEffect(() => {
  action.value.isEmpty = action.value.midiNote == null
})
</script>

<template>
  <v-select color="primary" variant="underlined" :label="translate('label:411')"
            :items="noteItems" v-model="note"></v-select>
  <v-select color="primary" variant="underlined" :label="translate('label:412')"
            :items="channelItems" v-model="channel"></v-select>
  <v-slider color="primary" :label="translate('label:413')" thumb-label
            :min="1" :max="127" :step="1" v-model="velocity"></v-slider>
  <v-text-field color="primary" variant="underlined" autocomplete="off"
                :label="translate('label:305')" v-model="action.comment"></v-text-field>
</template>

<style scoped></style>
