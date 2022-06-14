<template>
  <div class="tailwind-scope">
    <div class="py-1 align-middle min-w-full">
      <table class="w-full divide-y divide-gray-100">
        <thead class="bg-gray-50">
          <tr>
            <slot name="thead" />
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
          <slot name="tbody" />
        </tbody>
      </table>
    </div>
  </div>
</template>
