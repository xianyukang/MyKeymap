<script setup lang="ts">
defineProps<{
  titles?: string[]
}>()
</script>

<template>
  <div class="Table" >
    <table class="my-table">
      <slot name="title">
        <tr>
          <th v-for="title in titles" :key="title">{{title}}</th>
        </tr>
      </slot>
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

th, :slotted(th) {
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

th {
  color: rgba(0, 0, 0, 1);
  font-size: 1.1em;
  background-color: rgb(245, 245, 245);
}

:deep(.v-select .v-field__append-inner i) {
  visibility: hidden;
}

:deep(tr) {
  color: rgba(0, 0, 0, 0.96);
}

:deep(.v-field--disabled .v-select__selection) {
  opacity: 0.5;
}

</style>
