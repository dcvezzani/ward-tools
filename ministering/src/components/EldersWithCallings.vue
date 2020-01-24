<template>
  <div class="elders-with-callings">
    
    <ul class="views">
      <li><a @click="view_mode = 'by_district'" href="#">By District</a></li>
      <li><a @click="view_mode = 'by_organization'" href="#">By Organization</a></li>
    </ul>

    <div v-if="view_mode == 'by_district'">
      <ul class="dl-jump-links">
        <li><a href="#d1">District 1 ({{leaders[0]}})</a></li>
        <li><a href="#d2">District 2 ({{leaders[1]}})</a></li>
        <li><a href="#d3">District 3 ({{leaders[2]}})</a></li>
      </ul>
    
      <h3><a name="d1">District 1 ({{leaders[0]}})</a></h3><br>
      <div v-for="elder in elders_d1" :key="elder.idx" class="elder">
        <Person :person="elder" :show-positions="true"></Person>
        <br/>
      </div>

      <h3><a name="d2">District 2 ({{leaders[1]}})</a></h3><br>
      <div v-for="elder in elders_d2" :key="elder.idx" class="elder">
        <Person :person="elder" :show-positions="true"></Person>
        <br/>
      </div>

      <h3><a name="d3">District 3 ({{leaders[2]}})</a></h3><br>
      <div v-for="elder in elders_d3" :key="elder.idx" class="elder">
        <Person :person="elder" :show-positions="true"></Person>
        <br/>
      </div>

    </div>

    <div v-if="view_mode == 'by_organization'">
      <ul>
        <li><a href="#ym">Aaronic Priesthood Quorums</a></li>
        <li><a href="#primary">Primary</a></li>
        <li><a href="#other">Other</a></li>
      </ul>

      <h3><a name="ym">Aaronic Priesthood Quorums</a></h3><br>
      <div v-for="elder in elders_ym" :key="elder.idx" class="elder">
        <Person :person="elder" :show-positions="true"></Person>
        <br/>
      </div>
    
      <h3><a name="primary">Primary</a></h3><br>
      <div v-for="elder in elders_primary" :key="elder.idx" class="elder">
        <Person :person="elder" :show-positions="true"></Person>
        <br/>
      </div>
    
      <h3><a name="other">Other</a></h3><br>
      <div v-for="elder in elders_others" :key="elder.idx" class="elder">
        <Person :person="elder" :show-positions="true"></Person>
        <br/>
      </div>
    </div>
  
  </div>
</template>

<script>
import elders from '../../../eq-members-with-aux-positions.json'
import Person from '@/components/Person.vue'
import { sort_by_name, sort_by } from '@/assets/js/utils'
const uuidv4 = require('uuid/v4');

export default {
  name: 'EldersWithCallings',
  components: { Person },
  props: {
    msg: String
  },
  data() {
    return {
      view_mode: 'by_district',
      leaders: ["Pres. Nitta", "Bro. Fidler", "Bro. Stilson"],
      elders: [],
      elders_d1: [],
      elders_d2: [],
      elders_d3: [],
      elders_ym: [],
      elders_primary: [],
      elders_others: [],
    }
  },
  mounted() {
    this.elders = elders.map(e => ({...e, uuid: uuidv4()})).sort(sort_by("district"))

    this.elders_d1 = this.elders.map(e => ({...e, idx: uuidv4()})).filter(e => e.district.match('^01')).sort(sort_by_name)
    this.elders_d2 = this.elders.map(e => ({...e, idx: uuidv4()})).filter(e => e.district.match('^02')).sort(sort_by_name)
    this.elders_d3 = this.elders.map(e => ({...e, idx: uuidv4()})).filter(e => e.district.match('^03')).sort(sort_by_name)

    
    this.elders_ym = this.elders.map(e => ({...e, idx: uuidv4()})).filter(e => e.positions.filter(p => p.organization === "Aaronic Priesthood Quorums").length > 0).sort(sort_by_name)
    this.elders_primary = this.elders.map(e => ({...e, idx: uuidv4()})).filter(e => e.positions.filter(p => p.organization === "Primary").length > 0).sort(sort_by_name)
    this.elders_others = this.elders.map(e => ({...e, idx: uuidv4()})).filter(e => e.positions.filter(p => (p.organization === "Aaronic Priesthood Quorums" || p.organization === "Primary")).length === 0).sort(sort_by_name)
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
h3 {
  background-color: whitesmoke;
}

.views, .dl-jump-links {
  margin: 1em 0;
}

br { display: none; }

</style>
