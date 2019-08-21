<template>
  <div class="elders-with-callings">

    <div v-for="sister in sisters" class="sister">
      <Person :person="sister" :show-positions="true"></Person>
      <br/>
    </div>
  
  </div>
</template>

<script>
import singleSisters from '../../../single-sisters.json'
import Person from '@/components/Person.vue'


export default {
  name: 'Sisters',
  components: { Person },
  props: {
    msg: String
  },
  data() {
    return {
      sisters: [],
    }
  },
  mounted() {
    this.sisters = singleSisters
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
  .sister {
    padding: 10px 0;
  }
  h3 {
    padding: 0;
    margin: 0;
  }
</style>
