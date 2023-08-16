<template>
  <td class="pl-6 py-2 whitespace-nowrap" @click="handleClick">
    <div v-if="readonly" style="width: 999px;">
      {{ cellValue }}
    </div>
    <input
      v-else
      type="text"
      ref="inputElement"
      @change="handleBlur"
      @keypress.enter="handleBlur"
      v-model="value"
      class="focus:ring focus:outline-none focus:ring-blue-500 w-full"
      style="width: 110px;"
    />
  </td>
</template>

<script>
export default {
  props: {
    cellKey: {
      type: String,
      default: "",
    },
    cellValue: {
      type: String,
      default: "",
    },
    readonly: {
      type: Boolean,
      default: false,
    },
  },
  data() {
    return {
      showInput: false,
      value: this.cellValue,
    };
  },
  methods: {
    handleClick() {
      this.showInput = true;
      // setTimeout(() => {
      //   this.$refs.inputElement.focus();
      // }, 200);
    },
    handleBlur() {
      this.showInput = false;
      this.$emit("changed", { key: this.cellKey, value: this.value });
    },
  },
};
</script>

<style>
</style>