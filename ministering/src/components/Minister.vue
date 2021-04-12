<template>
  <div class="supervisor" v-if="type == 'supervisor'">
    Presidency Member: <span class="minister-name">{{ name }}</span> <span class="contact-info"> <span>{{ phone }}</span> | <span>{{ email }}</span> </span>
  </div>
  <div class="minister-details" v-else="">
    <div>
      <div class="minister-name">{{ name }}</div>
      <div v-html="formattedAddress"></div>
      <div>{{ phone }}</div>
      <div>{{ email }}</div>
    </div>
    <YearbookEntry v-if="Object.keys(photoModifications).length > 0" :entry="entry" :photoModifications="photoModifications[entry.uuid]"></YearbookEntry>
    
  </div>
</template>

<script>
import YearbookEntry from './YearbookEntry.vue'

export default {
  name: 'Minister',
  props:['type', 'yearbook'],
  components: { YearbookEntry },
  sync:['name', 'address', 'phone', 'email'],
  computed: {
    formattedAddress: function () {
      return this.address.replace(/\n/, "<br/>")
    },
    photoModificationsLoaded: function() {
      return (this.photoModifications && Object.keys(this.photoModifications).length > 0)
    },
    entry: function() {
      return this.yearbook.find(entry => entry.name === this.name.replace(/[^A-Za-z,á\. ]/g, ''))
      
    }
  },
  methods: {
    loadPhotoAttributes: function() {
      return fetch('http://localhost:3000/yearbook-photo-attributes', {
        method: "GET",
        headers: {'content-type': 'application/json; charset=UTF-8'},
      })
      .then(data => data.json())
      .then(res => res.data)
      .catch(err => {
        console.error(err)
      })
    },
  },
  data: function () {
    return {
      // yearbook: [],
      photoModifications: {},
    }
  },
  async mounted() {
    // this.yearbook=this.$parent.$parent.yearbookEntries
  
    if (this.yearbook) {
      const _photoModifications = this.yearbook.reduce((entries, entry) => {
        entries[entry.uuid] = {backgroundSize: 'cover', backgroundPositionX: 'center', backgroundPositionY: 'center', active: 'elderPhoto'}
        return entries
      }, {})
      
      this.photoModifications = {..._photoModifications, ...(await this.loadPhotoAttributes())}
    }
    console.log(">>>this.photoModifications", this.photoModifications)
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style >
.minister-name {
  font-weight: bold;
}
.contact-info {
  padding-left: 2em;
}
.supervisor {
  margin: 0 0 1em 0;
  font-style: italic;
}

.yearbook-entry .label {
  position: absolute;
  background-color: white;
  padding: 0 1em;
  opacity: 0.8;
  display: block;
  white-space: nowrap;
  bottom: 0;
  width: 100%;
  font-weight: bold;
}

.yearbook-entry .photo {
  position: relative;
  border: 5px solid white;
}

.minister-details {
  display: flex;
}

.minister-details div:first-child {
  width: 250px;
}

</style>

