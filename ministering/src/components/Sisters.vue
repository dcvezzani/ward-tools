<template>
  <div class="elders-with-callings">

    <ul>
      <li><a @click="view_mode = 'by_district'" href="#">By District</a></li>
      <li><a @click="view_mode = 'by_name'" href="#">By Name</a></li>
    </ul>

    <div v-if="view_mode == 'by_district'">
      <ul>
        <li><a href="#d1">District 1 ({{leaders[0]}})</a></li>
        <li><a href="#d2">District 2 ({{leaders[1]}})</a></li>
        <li><a href="#d3">District 3 ({{leaders[2]}})</a></li>
      </ul>
    
      <h3><a name="d1">District 1 ({{leaders[0]}})</a></h3><br>
      <div v-for="sister in sisters_d1" :key="sister.idx" class="sister">
        <Person :person="sister" :show-positions="true"></Person>
        <br/>
      </div>

      <h3><a name="d2">District 2 ({{leaders[1]}})</a></h3><br>
      <div v-for="sister in sisters_d2" :key="sister.idx" class="sister">
        <Person :person="sister" :show-positions="true"></Person>
        <br/>
      </div>

      <h3><a name="d3">District 3 ({{leaders[2]}})</a></h3><br>
      <div v-for="sister in sisters_d3" :key="sister.idx" class="sister">
        <Person :person="sister" :show-positions="true"></Person>
        <br/>
      </div>
    </div>
  
    <div v-if="view_mode == 'by_name'">
      <div v-for="sister in sisters" :key="sister.idx" class="sister">
        <Person :person="sister" :show-positions="true"></Person>
        <br/>
      </div>
    </div>
  
  </div>
</template>

<script>
import singleSisters from '../../../single-sisters.json'
import Person from '@/components/Person.vue'
import { sort_by_name, sort_by } from '@/assets/js/utils'
const uuidv4 = require('uuid/v4');

export default {
  name: 'Sisters',
  components: { Person },
  props: {
    msg: String
  },
  data() {
    return {
      view_mode: 'by_district',
      leaders: ["Pres. Nitta", "Bro. Fidler", "Bro. Stilson"],
      sisters: [],
      sisters_d1: [],
      sisters_d2: [],
      sisters_d3: [],
      sisters_ym: [],
      sisters_primary: [],
      sisters_others: [],
    }
  },
  mounted() {
    this.sisters = singleSisters.map(e => ({...e, idx: uuidv4()})).sort(sort_by_name)

    this.sisters_d1 = this.sisters.map(e => ({...e, idx: uuidv4()})).filter(e => e.district.match('^01')).sort(sort_by_name)
    this.sisters_d2 = this.sisters.map(e => ({...e, idx: uuidv4()})).filter(e => e.district.match('^02')).sort(sort_by_name)
    this.sisters_d3 = this.sisters.map(e => ({...e, idx: uuidv4()})).filter(e => e.district.match('^03')).sort(sort_by_name)
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
  .sister {
  }
  h3 {
    background-color: whitesmoke;
  }
</style>
