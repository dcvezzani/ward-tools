<template>
  <div class="yearbook">
    <div class="filters">
      Filters (include): 
      <span>Residential</span>
      <input type="radio" id="filter-type-residential" name="filter-type" v-model="filterType" value="residential"/> <label for="filter-type-residential">Residential</label>
      <input type="radio" id="filter-type-ministering" name="filter-type" v-model="filterType" value="ministering"/> <label for="filter-type-ministering">Ministering</label>
    </div>

    <div class="filters">
      Filters (include): 
      <span>Ministering</span>
      <input type="checkbox" id="district-01" v-model="filters.district01.value" /> <label for="district-01">District 1</label>
      <input type="checkbox" id="district-02" v-model="filters.district02.value" /> <label for="district-02">District 2</label>
      <input type="checkbox" id="district-03" v-model="filters.district03.value" /> <label for="district-03">District 3</label>
      <input type="checkbox" id="district-unassigned" v-model="filters.unassigned.value" /> <label for="district-unassigned">Unassigned</label>
      <!--
      <input type="checkbox" id="alloy" v-model="filters.alloy.value" /> <label for="alloy">Alloy</label>
      <input type="checkbox" id="sterling-loop" v-model="filters['sterling-loop'].value" /> <label for="sterling-loop">Sterling Loop</label>
      -->
    </div>

    <div><button @click="savePhotoAttributes">save</button> | <button @click="loadPhotoAttributes">load</button></div>

    <div class="yearbook-entries">
      <YearbookEntry v-if="photoModificationsLoaded && filteredYearbook" v-for="entry in filteredYearbook" :key="entry.id" :entry="entry" :photoModifications="photoModifications[entry.id]" isEditable="true">
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
      filterType: 'residential',
      filters: {
        district01: {value: true, id: '01'},
        district02: {value: true, id: '02'},
        district03: {value: true, id: '03'},

        ministeringDistrict01: {value: false, id: '01'},
        ministeringDistrict02: {value: false, id: '02'},
        ministeringDistrict03: {value: false, id: '03'},

        alloy: {value: false, id: 'alloy'},
        'sterling-loop': {value: false, id: 'sterling-loop'},
        unassigned: {value: false, id: 'unassigned'},
      },
      selectedUuid: null,
    }
  },
  computed: {
    filteredYearbook: function() {
      const activeFilters = Object.keys(this.filters).filter(key => this.filters[key].value)
      const activeDistrictIds = activeFilters.map(key => this.filters[key].id)
      // return this.yearbook.filter(entry => activeDistrictIds.some(id => entry.district.includes(id)) || activeDistrictIds.some(id => entry.ministeringDistrict.includes(id)))
      const compareProperty = (this.filterType === 'residential') ? 'district' : 'ministeringDistrict'
      let activeYearBookEntries = this.yearbook.filter(entry => activeDistrictIds.some(id => entry[compareProperty] && entry[compareProperty].includes(id)))

      console.log(">>>activeFilters", activeFilters)
      if (activeFilters.includes('unassigned')) 
        activeYearBookEntries = activeYearBookEntries.concat(this.yearbook.filter(entry => activeDistrictIds.some(id => !entry[compareProperty])))

      return activeYearBookEntries
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
    const self = this
    this.yearbook = yearbook
    // window.selectedPhotoUuid = null

    const _photoModifications = yearbook.reduce((entries, entry) => {
      entries[entry.id] = {backgroundSize: 'cover', backgroundPositionX: 'center', backgroundPositionY: 'center', active: 'elderPhoto'}
      return entries
    }, {})
    
    this.photoModifications = {..._photoModifications, ...(await this.loadPhotoAttributes())}

    // if (!this.photoModifications) {
    //   this.photoModifications = yearbook.reduce((entries, entry) => {
    //     entries[entry.id] = {backgroundSize: 'cover', backgroundPositionX: 'center', backgroundPositionY: 'center', active: 'elderPhoto'}
    //     return entries
    //   }, {})
    // }

    document.onkeydown = function(evt) {
        evt = evt || window.event;
        const offset = (evt.shiftKey && evt.ctrlKey) ? 500 : (evt.ctrlKey) ? 50 : (evt.shiftKey) ? 100 : 15

        const photoId = (window.targetPhoto) ? window.targetPhoto.getAttribute('data-id') : null
        // console.log(">>>window.targetPhoto", window.targetPhoto, photoId)
        // console.log(">>>window.selectedPhotoUuid", window.selectedPhotoUuid)

        // if (evt.ctrlKey && evt.keyCode == 90) {
        //     alert("Ctrl-Z");
        // }
        // if (evt.keyCode == 84) { selectPhoto(evt,  {actionType: 'key-code-t', selected: true}) }
        if (evt.keyCode == 84) Event.$emit('selectPhotoHandler', {evt, data: {actionType: 'key-code-t', selected: true}})
        
        /* if (evt.keyCode == 84) { */
        /*   const photoId = (window.candidatePhoto) ? window.candidatePhoto.getAttribute('data-id') : null */
        /*   if (photoId) Event.$emit(photoId, {action: 'selectPhoto', data: {actionType: 'key-code-t', selected: true}}) */
        /* } */
        // else if (evt.keyCode == 84) Event.$emit(dataId, {action: 'selectPhoto', ...{actionType: 'key-code-t', selected: true}})

        else if (photoId) {
          if (evt.keyCode == 82) Event.$emit(photoId, {action: 'resetPhoto', data: {actionType: 'key-code-r'}})

          else if (evt.keyCode == 188) Event.$emit(photoId, {action: 'zoomOut', data: {actionType: 'key-code-comma', offset}})
          else if (evt.keyCode == 190) Event.$emit(photoId, {action: 'zoomIn', data: {actionType: 'key-code-period', offset}})

          else if (evt.keyCode == 87)  Event.$emit(photoId,    {action: 'scrollUp', data: {actionType: 'key-code-w', offset}})
          else if (evt.keyCode == 83)  Event.$emit(photoId,  {action: 'scrollDown', data: {actionType: 'key-code-s', offset}})
          else if (evt.keyCode == 65)  Event.$emit(photoId,  {action: 'scrollLeft', data: {actionType: 'key-code-a', offset}})
          else if (evt.keyCode == 68)  Event.$emit(photoId, {action: 'scrollRight', data: {actionType: 'key-code-d', offset}})
          else {
            console.log(">>>evt.keyCode", evt.keyCode)
          }
        }
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
