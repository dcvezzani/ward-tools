<template>
  <div class="home">
    <Ministering msg="Welcome to Your Vue.js App"/>
  </div>
</template>

<script>
// @ is an alias to /src
import Ministering from '@/components/Ministering.vue'

export default {
  name: 'home',
  components: {
    Ministering
  }
}
</script>
