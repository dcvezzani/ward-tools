<template>
  <div class="text-lists">
    <button @click="showGivenName = !showGivenName">Toggle Given Name</button>
    <div class="text-list-entry" v-for="elder in eldersWithPhone">
      <TextListEntry
        :entry="elder"
        :showGivenName="showGivenName"
        inline-template>
        <div>
          <span>{{elder.phone}}</span><span>,{{elder.surname}}</span><span v-show="showGivenName">,{{elder.givenName}}</span>
        </div>
      </TextListEntry>
    </div>
  </div>
</template>

<script>
import Vue from 'vue'
import availableEqMembers from '../../../available_eq.json'
import Person from '@/components/Person.vue'
const uuidv4 = require('uuid/v4');


Vue.component('TextListEntry', {
  // components: { },
  props: ['elder', 'showGivenName'],
  computed: {
  },
  data: function () {
    return {
    }
  },
})

export default {
  name: 'TextList',
  components: { Person },
  props: {
    msg: String
  },
  computed: {
    eldersWithPhone: function() {
      return this.elders.filter(elder => elder.phone && elder.phone.length > 0)
    },
    eldersWithEmail: function() {
      return this.elders.filter(elder => elder.email && elder.email.length > 0)
    },
  },
  data() {
    return {
      elders: [],
      showGivenName: true,
    }
  },
  methods: {
    cleanPhone: function(phone) {
      return (phone) ? phone.replace(/[-()\. ]/g, '') : ''
    },
    cleanEmail: function(email) {
      return (email) ? email : '(none)'
    },
    cleanSurname: function(name) {
      return (name) ? name.replace(/\'/g, '') : ''
    },
  },
  mounted() {
    this.elders = availableEqMembers.filter(e => ['HIGH_PRIEST', 'ELDER'].includes(e.priesthood)).map(e => ({givenName: e.givenName, surname: this.cleanSurname(e.surname), phone: this.cleanPhone(e.phone), email: this.cleanEmail(e.email), idx: uuidv4()}))
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

  .views, .dl-jump-links {
    margin: 1em 0;
  }
  
  /* br { display: none; } */
</style>
