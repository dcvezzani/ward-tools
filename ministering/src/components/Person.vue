<template>
  <div class="person">
    <h3 class="name">{{person.name}}</h3>
    <div class="address"><span class="label">Address: </span>(<span class="district">{{person.district}}</span>) </span><span class="value" v-html="person.address"></span></div>
    <div class="phone"><span class="label">Phone: </span><span class="value"><a :href="phone">{{person.phone}}</a></span></div>
    <div class="email"><span class="label">Email: </span><span class="value"><a :href="email">{{person.email}}</a></span></div>
    <div class="age"><span class="label">Age: </span><span class="value">{{person.age}}</span></span></div>

    <CallingPosition v-for="position in person.positions" :position="position"
      inline-template>
      <ul class="position">
        <li class="position-details"><span class="label">Unit Name: </span><span class="value">{{position.unitName}}</span>; <span class="label">Organization: </span><span class="value">{{position.organization}}</span>; <span class="label">Position: </span><span class="value">{{position.position}}</span></li>
      </ul>
    </CallingPosition>
  </div>
</template>

<script>
import Vue from 'vue'

Vue.component('CallingPosition', {
  name: 'CallingPosition',
  props: ['positions'],
  data: function () {
    return {
    }
  },
})

export default {
  name: 'Person',
  components: { },
  props: ['person', 'show-positions'],
  computed: {
    phone: function() {
      return `tel:${this.person.phone}`
    },
    email: function() {
      return `mailto:${this.person.email}`
    },
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style >
  .person {
    padding: 10px 0;
  }
  h3 {
    padding: 0;
    margin: 0;
  }

  .district {
    display: inline-block;
    width: inherit;
  }

  .position, 
  .position .position-details {
    padding: 0 *; 
    margin: 0; 
  }
  
</style>
