<template>
  <div class="elders-with-callings">

    <div v-for="elder in elders" class="elder">
      <Person :person="elder" :show-positions="true"></Person>
      <br/>
    </div>
  
  </div>
</template>

<script>
import elders from '../../../eq-members-with-aux-positions.json'
import Person from '@/components/Person.vue'

export default {
  name: 'EldersWithCallings',
  components: { Person },
  props: {
    msg: String
  },
  data() {
    return {
      elders: [],
    }
  },
  mounted() {
    this.elders = elders
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
</style>
