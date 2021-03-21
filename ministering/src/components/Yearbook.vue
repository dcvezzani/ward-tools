<template>
  <div class="yearbook">
    <div class="filters">
      Filters (include): 
      <input type="checkbox" id="district-01" v-model="filters.district01.value" /> <label for="district-01">District 1</label>
      <input type="checkbox" id="district-02" v-model="filters.district02.value" /> <label for="district-02">District 2</label>
      <input type="checkbox" id="district-03" v-model="filters.district03.value" /> <label for="district-03">District 3</label>
      <input type="checkbox" id="alloy" v-model="filters.alloy.value" /> <label for="alloy">Alloy</label>
      <input type="checkbox" id="sterling-loop" v-model="filters['sterling-loop'].value" /> <label for="sterling-loop">Sterling Loop</label>
    </div>

    <div><button @click="savePhotoAttributes">save</button> | <button @click="loadPhotoAttributes">load</button></div>

    <div class="yearbook-entries">
      <YearbookEntry v-if="photoModificationsLoaded && filteredYearbook" v-for="entry in filteredYearbook" :key="entry.uuid" :entry="entry" :photoModifications="photoModifications[entry.uuid]">
      </YearbookEntry>
    </div>
  </div>
</template>

<script>
import Vue from 'vue'
import yearbook from '../../../yearbook.json'
import YearbookEntry from './YearbookEntry.vue'

window.photos = []
window.candidatePhoto = null
window.targetPhoto = null

export default {
  name: 'Yearbook',
  components: {YearbookEntry},
  data() {
    return {
      yearbook: [],
      photoModifications: {},
      filters: {
        district01: {value: true, id: '01'},
        district02: {value: true, id: '02'},
        district03: {value: true, id: '03'},
        alloy: {value: false, id: 'alloy'},
        'sterling-loop': {value: false, id: 'sterling-loop'},
      }
    }
  },
  computed: {
    filteredYearbook: function() {
      const activeDistrictIds = Object.keys(this.filters).filter(key => this.filters[key].value).map(key => this.filters[key].id)
      return this.yearbook.filter(entry => activeDistrictIds.some(id => entry.district.includes(id)))
    },
    photoModificationsLoaded: function() {
      return (this.photoModifications && Object.keys(this.photoModifications).length > 0)
    }
  },
  methods: {
    savePhotoAttributes: function() {
      fetch('http://localhost:3000/yearbook-photo-attributes', {
        method: "POST",
        headers: {'content-type': 'application/json; charset=UTF-8'},
        body: JSON.stringify({data: this.photoModifications}),
      })
      .then(data => data.json())
      .then(res => console.log(res))
      .catch(err => console.error(err))
      
    },
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
  async mounted() {
    this.yearbook = yearbook

    const _photoModifications = yearbook.reduce((entries, entry) => {
      entries[entry.uuid] = {backgroundSize: 'cover', backgroundPositionX: 'center', backgroundPositionY: 'center', active: 'elderPhoto'}
      return entries
    }, {})
    
    this.photoModifications = {..._photoModifications, ...(await this.loadPhotoAttributes())}

    // if (!this.photoModifications) {
    //   this.photoModifications = yearbook.reduce((entries, entry) => {
    //     entries[entry.uuid] = {backgroundSize: 'cover', backgroundPositionX: 'center', backgroundPositionY: 'center', active: 'elderPhoto'}
    //     return entries
    //   }, {})
    // }

    document.onkeydown = function(evt) {
        evt = evt || window.event;
        const offset = (evt.shiftKey && evt.ctrlKey) ? 500 : (evt.ctrlKey) ? 50 : (evt.shiftKey) ? 100 : 15

        // if (evt.ctrlKey && evt.keyCode == 90) {
        //     alert("Ctrl-Z");
        // }
        if (false) {}
        else if (evt.keyCode == 84) { selectPhoto(evt,  {actionType: 'key-code-t', selected: true}) }
        else if (evt.keyCode == 82) { resetPhoto(evt,   {actionType: 'key-code-r'}) }
        else if (evt.keyCode == 188) { zoomOut(evt,     {actionType: 'key-code-comma', offset}) }
        else if (evt.keyCode == 190) { zoomIn(evt,      {actionType: 'key-code-period', offset}) }
        else if (evt.keyCode == 87)  { scrollUp(evt,    {actionType: 'key-code-w', offset}) }
        else if (evt.keyCode == 83)  { scrollDown(evt,  {actionType: 'key-code-s', offset}) }
        else if (evt.keyCode == 65)  { scrollLeft(evt,  {actionType: 'key-code-a', offset}) }
        else if (evt.keyCode == 68)  { scrollRight(evt, {actionType: 'key-code-d', offset}) }
        else {
          console.log(">>>evt.keyCode", evt.keyCode)
        }
    };
  },
  beforeDestroy() {
    document.onkeydown = null
  },
}

/*
const selectPhotos = () => {
  window.photos = document.querySelectorAll(".yearbook .photo");
  if (window.photos.length < 1) return setTimeout(() => { selectPhotos() }, 1000)
  console.log("photos have been loaded!")
  window.photos.forEach(photo => {
    photo.addEventListener("mouseover", onmouseoverHandler)
    photo.addEventListener("mouseout", onmouseoutHandler)
    photo.addEventListener("mousedown", onmousedownHandler)
  });
}

const selectPhoto = (selected) => {
  if (!selected) {
    window.targetPhoto.classList.remove("selected")
    return window.targetPhoto = null
  }

  if (!window.candidatePhoto) return setTimeout(() => { selectPhoto() }, 1000)
  window.targetPhoto = window.candidatePhoto
  window.targetPhoto.classList.add("selected")
}

*/

</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style >
.yearbook-entries {
  display: flex;
  flex-direction: row;
  flex-wrap: wrap;
}

.yearbook .label {
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
.yearbook .photo {
  position: relative;
  border: 5px solid white;
}

.yearbook .photo.selected {
  border: 5px solid orange;
}

.label .text {
  display: block;
  width: 87%;
}

.truncate {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.filters input {
margin-left: 2em;
margin-right: 5px;
}
.filters input:first-child {
margin-left: 1em;
}
</style>
