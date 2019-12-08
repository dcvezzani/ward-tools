<template>
  <div class="email-lists">
    <button @click="showGivenName = !showGivenName">Toggle Given Name</button>
    <div class="email-list-entry" v-for="elder in eldersWithPhone">
      <EmailListEntry
        :entry="elder"
        :showGivenName="showGivenName"
        inline-template>
        <div>
          <span v-if="elder.email && elder.email.length > 0">
            &quot;<span>{{elder.surname}}</span><span v-show="showGivenName">,{{elder.givenName}}</span>&quot;<span>&lt;{{elder.email}}&gt;</span>
          </span>
        </div>
      </EmailListEntry>
    </div>
  </div>
</template>

<script>
import Vue from 'vue'
import availableEqMembers from '../../../available_eq.json'
import Person from '@/components/Person.vue'
const uuidv4 = require('uuid/v4');


Vue.component('EmailListEntry', {
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
  name: 'EmailList',
  components: { Person },
  props: {
    msg: String
  },
  computed: {
    eldersWithPhone: function() {
      return this.elders.filter(elder => elder.phone && elder.phone.length > 0)
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
    cleanName: function(name) {
      return (name) ? name.replace(/\'\"/g, '') : ''
    },
  },
  mounted() {
    this.elders = availableEqMembers.filter(e => ['HIGH_PRIEST', 'ELDER'].includes(e.priesthood)).map(e => ({givenName: this.cleanName(e.givenName), surname: this.cleanName(e.surname), phone: this.cleanPhone(e.phone), email: e.email, idx: uuidv4()}))
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
