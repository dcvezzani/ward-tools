<template>
  <div class="reports">
    <EldersWithCallings></EldersWithCallings>
  </div>
</template>

<script>
// @ is an alias to /src
import EldersWithCallings from '@/components/EldersWithCallings.vue'

export default {
  name: 'reports',
  components: {
    EldersWithCallings
  }
}
</script>
