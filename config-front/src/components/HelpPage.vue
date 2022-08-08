<template>
  <div>
    <div id="HelpPage" v-if="config">
      <div class="fixed border-r h-full px-4 bg-gray-100">
        <ul>
          <li v-for="(value, key) in config" :key="key">
            <a
              class="block text-green py-3 text-[#0d7a79]"
              :href="`#${uriComponent(key)}`"
              >{{ key }}</a
            >
          </li>
        </ul>
      </div>
      <div class="ml-60">
        <div class="m-6" v-for="(value, key) in config" :key="key">
          <a
            :id="uriComponent(key)"
            :href="`#${uriComponent(key)}`"
            class="font-bold text-2xl pl-1 text-[#d05]"
            >{{ key }}</a
          >
          <div
            class="
              flex flex-wrap flex-col
              w-96
              shadow-neutral-400
              border-gray-400
              p-2
              max-h-80
              rounded
            "
          >
            <div
              class="p-2 text-gray-700"
              v-for="(value, index) in value"
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
    </div>
  </div>
</template>

<script>
import _ from "lodash";
import { getKeymapName, isModeEnabled, KEYMAP_PLUS_ABBR } from "../util";
import { getLabelByValue } from "../action";

// import "../style/HelpPage.css"; // 预览帮助页样式, 另外还需要去 App.vue 中修改 v-show

function windowSelectorList(config) {
  return [
    { id: "2", key: "" },
    ...config.windowSelectors.filter((x) => x.value),
  ];
}

function parseConfig(config) {
  if (!config) return null;

  const res = {};
  for (const keymap of KEYMAP_PLUS_ABBR) {
    if (!isModeEnabled(keymap, config.Settings)) {
      continue;
    }

    for (const sel of windowSelectorList(config)) {
      if (!getKeymapName[keymap]) {
        continue
      }
      const name = getKeymapName[keymap] + ` ${sel.key}`;
      res[name] = []; // res[name] 表示 <某模式> 在 <某应用> 包含的按键映射

      for (const [key, keyConfig] of Object.entries(config[keymap])) {
        if (!keyConfig) {
          continue
        }
        const desc = getDesc(keyConfig[sel.id]);
        if (desc) {
          res[name].push({ key, desc });
        }
      }

      res[name] = _.sortBy(res[name], "desc");
      if (res[name].length == 0) {
        delete res[name];
      }
    }
  }
  return res;
}

function getDesc(config) {
  if (!config) return "";
  if (config.type == "什么也不做") return "";
  if (config.comment) return config.comment;
  if (getLabelByValue[config.value]) return getLabelByValue[config.value];
  if (config.label) return config.label;

  if (config.type === "启动程序或激活窗口") {
    return "启动某个程序 (缺备注)";
  }

  if (config.type === "输入文本或按键" && config.keysToSend) {
    if (config.keysToSend.includes("\n"))
      return "输入 " + config.keysToSend.split("\n")[0] + "...";
    else return "输入 " + config.keysToSend;
  }

  if (config.value.startsWith("bindOrActivate(")) {
    return "绑定当前窗口到这个键";
  }
  if (config.value.startsWith("bindOrActivate_unbind(")) {
    return "取消当前窗口的键绑定";
  }

  return config.value;
}

export default {
  data() {
    return {
      KEYMAP_PLUS_ABBR,
    };
  },
  methods: {
    uriComponent: encodeURIComponent,
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