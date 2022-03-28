<template>
  <div id="HelpPage" v-show="show" v-if="config">
    <div class="m-10">
      <h1 class="font-bold text-2xl pl-1 text-[#d05]">Capslock</h1>
      <div
        class="
          flex
          flex-wrap
          flex-col
          border
          shadow-md
          shadow-neutral-400
          border-gray-400
          p-4
          max-h-64
          rounded
        "
      >
        <div
          class="p-2 w-64 text-gray-700"
          v-for="(value, index) in config.Capslock"
          :key="index"
        >
          <span
            class="
              border border-gray-400
              rounded
              px-3
              py-1
              bg-gray-100
              text-blue-600
              font-bold
              text-lg
              shadow
            "
            >{{ value.key }}</span
          >
          {{ value.desc }}
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import _ from "lodash";
import "../style/HelpPage.css"; // 预览帮助页样式
import { KEYMAP_PLUS_ABBR } from "../util";
const show = true;

function parseConfig(config) {
  if (!config) return null;

  const res = {};
  for (const keymap of KEYMAP_PLUS_ABBR) {
    res[keymap] = [];
    for (const [key, keyConfig] of Object.entries(config[keymap])) {
      const desc = getDesc(keyConfig);
      if (desc) {
        res[keymap].push({ key, desc });
      }
    }
    res[keymap] = _.sortBy(res[keymap], "desc");
  }
  return res;
}

function getDesc(keyConfig) {
  const config = keyConfig["2"];
  if (config.type == "什么也不做") return "";
  // if (config.comment) return config.comment;
  return config.type;
}

export default {
  data() {
    return {
      show,
    };
  },
  computed: {
    config() {
      return parseConfig(this.$store.state.config);
    },
  },
};
</script>

<style>
</style>