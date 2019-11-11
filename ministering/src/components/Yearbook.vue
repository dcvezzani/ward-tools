<template>
  <div class="yearbook">
    <div><button @click="savePhotoAttributes">save</button> | <button @click="loadPhotoAttributes">load</button></div>
    <YearbookEntry v-if="photoModificationsLoaded" v-for="entry in yearbook" :key="entry.uuid" :entry="entry" :photoModifications="photoModifications[entry.uuid]" class="yearbook-entry" inline-template>
      <div :data-id="entry.uuid" @mouseover="onmouseoverHandler" @mousedown="onmousedownHandler" @mouseout="onmouseoutHandler" @click="toggleMode" :class="classNames" :style="modeStyle"><span class="label"><span class="text truncate">{{ entry.name }}</span></span></div>
    </YearbookEntry>
  </div>
</template>

<script>
import Vue from 'vue'
import yearbook from '../../../yearbook.json'

window.photos = []
window.candidatePhoto = null
window.targetPhoto = null

const onmouseoverHandler = (evt) => {
  evt = evt || window.event;
  highlightPhoto(evt, {highlighted: true, type: 'mouse-over'})
}

const onmouseoutHandler = (evt) => {
  evt = evt || window.event;
  highlightPhoto(evt, {highlighted: false, type: 'mouse-out'})
}

const onmousedownHandler = (evt) => {
  evt = evt || window.event;
  selectPhoto(evt, {selected: true, type: 'mouse-down'})
}

const highlightPhoto = (evt, {highlighted, actionType}) => {
  const dataId = evt.target.getAttribute("data-id")
  if (dataId) {
    if (highlighted) {
      Event.$emit(dataId, {action: 'highlightPhoto', type: actionType, data: {highlighted: true}})
      window.candidatePhoto = evt.target
    }
    else {
      Event.$emit(dataId, {action: 'highlightPhoto', type: actionType, data: {highlighted}})
      if (!highlighted) window.candidatePhoto = null
    }
  }
}

const selectPhoto = (evt, {selected, actionType}) => {
  const oldDataId = window.targetPhoto && window.targetPhoto.getAttribute("data-id")
  const newDataId = window.candidatePhoto && window.candidatePhoto.getAttribute("data-id")

  if (oldDataId) {
    Event.$emit(oldDataId, {action: 'selectPhoto', type: actionType, data: {selected: !selected}}) 
  }
  if (newDataId) {
    Event.$emit(newDataId, {action: 'selectPhoto', type: actionType, data: {selected}}) 
  }
  window.targetPhoto = window.candidatePhoto
}

const resetPhoto = (evt) => {
  const dataId = window.targetPhoto.getAttribute("data-id")
  Event.$emit(dataId, {action: 'resetPhoto'}) 
}

const zoomOut = (evt, {offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = window.targetPhoto.offsetWidth
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'zoomOut', data: {attribute: 'backgroundSize', offset, defaultVal, label: 'px'}})
}

const zoomIn = (evt, {offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = window.targetPhoto.offsetWidth
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'zoomIn', data: {attribute: 'backgroundSize', offset: (-1)*offset, defaultVal, label: 'px'}})
}

const scrollUp = (evt, {offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = 0
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'scrollUp', data: {attribute: 'backgroundPositionY', offset, defaultVal, label: 'px'}})
}

const scrollDown = (evt, {offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = 0
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'scrollDown', data: {attribute: 'backgroundPositionY', offset: (-1)*offset, defaultVal, label: 'px'}})
}

const scrollLeft = (evt, {offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = 0
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'scrollLeft', data: {attribute: 'backgroundPositionX', offset, defaultVal, label: 'px'}})
}

const scrollRight = (evt, {offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = 0
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'scrollRight', data: {attribute: 'backgroundPositionX', offset: (-1)*offset, defaultVal, label: 'px'}})
}

const getSize = (targetElement, defaultValue) => {
  return (targetElement.match(/\d+px/)) ? parseInt(targetElement.replace(/px/, '')) : defaultValue
}

Vue.component('YearbookEntry', {
  props:['entry', 'photoModifications'],
  data() {
    return {
      highlighted: false,
      selected: false,
    }
  },
  computed: {
    photoMods: function() {
      return this.photoModifications
      //return (this.photoModifications)
      //  ? this.photoModifications
      //  : {active: 'elderPhoto', backgroundPositionX: 'center', backgroundPositionY: 'center', backgroundSize: 'cover'}
    },
    modeStyle: function() {
      return "background: url('" + this.removeQuotes(this.entry[this.photoMods.active]) + "') " + this.photoMods.backgroundPositionX + " " + this.photoMods.backgroundPositionY + " / " + this.photoMods.backgroundSize + " no-repeat rgb(255, 255, 255); display: inline-block; height: 200px; width: 200px;"
    },
    classNames: function() {
      return ['photo', (this.selected || this.highlighted) ? 'selected' : '']
    },
  },
  methods: {
    onmouseoverHandler,
    onmouseoutHandler,
    onmousedownHandler,
    // TODO: consider keeping data clean from the start; the problem starts with the data in LCR; "name": "Vezzani, Jordan \"Vezzani\"",
    removeQuotes: function (val) { 
      return val.replace(/\"/g, '')
    },
    toggleMode: function () {
      this.photoModifications.active = (this.photoModifications.active != 'elderPhoto') ? 'elderPhoto' : 'familyPhoto'
    },
    highlightPhoto: function ({highlighted}) {
      this.highlighted = highlighted
    },
    selectPhoto: function ({selected}) {
      this.highlighted = false
      this.selected = selected
    },
    resetPhoto: function () {
      this.photoModifications.backgroundPositionX = 'center'
      this.photoModifications.backgroundPositionY = 'center'
      this.photoModifications.backgroundSize = 'cover'
      this.photoModifications.active = 'elderPhoto'
    },
  },
  mounted() {
    const self = this
    Event.$on(this.entry.uuid, function(payload){
      // console.log(`>>>payload from ${self.entry.uuid}`, payload)
      switch(payload.action) {
        case 'photo-manipulation':
          const {attribute, offset, defaultVal, label} = payload.data
          const currentValue = getSize(self.photoModifications[attribute], defaultVal)
          return self.photoModifications[attribute] = (currentValue - offset) + "px"

        default:
          return self[payload.action](payload.data)
      }
    });
  },
  beforeDestroy() {
    Event.$off()
  },
})

export default {
  name: 'Yearbook',
  data() {
    return {
      yearbook: [],
      photoModifications: {},
    }
  },
  computed: {
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
</style>
