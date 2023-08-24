<script setup lang="ts">
</script>

<template>
  <div class="Table" >
    <table class="my-table">
      <slot></slot>
    </table>
  </div>
</template>

<style scoped>
table {
  border-collapse: collapse;
  width: 100%;
  height: 3rem;
}

:slotted(th) {
  font-weight: 500;
  color: rgba(var(--v-theme-on-surface),var(--v-medium-emphasis-opacity));

  padding: 0 1rem 0 1rem;
  height: 3rem;
  border-bottom: 1px solid #e4e4e4;
}

:slotted(td) {
  padding: 0 1rem 0 1rem;
  height: 3rem;
  border-bottom: 1px solid #e4e4e4;
}

:slotted(tr:hover:not(:first-child)) {
  background: #E3F2FD;
}

</style>