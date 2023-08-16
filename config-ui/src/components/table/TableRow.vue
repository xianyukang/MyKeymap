<template>
  <tr class="hover:cursor-pointer">
    <TableCell :cell-value="person.name" :cellKey="'name'" @changed="handleChange">
      {{ person.name }}
    </TableCell>
    <TableCell :cell-value="person.email" :cellKey="'email'" @changed="handleChange">
      {{ person.email }}
    </TableCell>
    <TableCell :cell-value="person.contact" :cellKey="'contact'" @changed="handleChange">
      {{ person.contact }}
    </TableCell>
  </tr>
</template>

<script>
import TableCell from "./TableCell.vue";
export default {
  components: {
    TableCell,
  },
  props: {
    person: {
      type: Object,
      required: true,
    },
  },
  methods: {
    handleChange(payload) {
      payload.id = this.person.id;
      this.$emit("personupdated", payload);
    },
  },
};
</script>

<style></style>
