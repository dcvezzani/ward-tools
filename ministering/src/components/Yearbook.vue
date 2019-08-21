<template>
  <div class="yearbook">
    <YearbookEntry v-for="entry in yearbook" :key="entry.uuid" :entry="entry" class="yearbook-entry" inline-template>
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
  if (window.targetPhoto) return
  evt = evt || window.event;
  // console.log(">>>evt.keyCode", evt.keyCode, evt.target)
  // console.log(">>>onmouseoverHandler", evt.target.getAttribute("data-id"))
  const dataId = evt.target.getAttribute("data-id")
  if (dataId) {
    Event.$emit(dataId, {action: 'highlightPhoto', type: 'mouse-over', data: {highlighted: true}})
    window.candidatePhoto = evt.target
  }
}

const onmouseoutHandler = (evt) => {
  if (window.targetPhoto) return
  evt = evt || window.event;
  // console.log(">>>onmouseoutHandler", evt.target.getAttribute("data-id"))
  const dataId = evt.target.getAttribute("data-id")
  if (dataId) {
    Event.$emit(dataId, {action: 'highlightPhoto', type: 'mouse-out', data: {highlighted: false}})
  }
}

const onmousedownHandler = (evt) => {
  evt = evt || window.event;
  if (window.targetPhoto) Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'selectPhoto', type: 'mouse-out', data: {selected: false}})
  window.candidatePhoto = evt.target
  Event.$emit(evt.target.getAttribute("data-id"), {action: 'selectPhoto', type: 'mouse-out', data: {selected: true}})
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
  props:['entry'],
  data() {
    return {
      mode: "elder",
      highlighted: false,
      selected: false,
    }
  },
  computed: {
    modeStyle: function() {
      return "background: url('" + this.entry[this.mode + "Photo"] + "') " + this.entry.backgroundPositionX + " " + this.entry.backgroundPositionY + " / " + this.entry.backgroundSize + " no-repeat rgb(255, 255, 255); display: inline-block; height: 200px; width: 200px;"
    },
    classNames: function() {
      return ['photo', (this.selected || this.highlighted) ? 'selected' : '']
    },
  },
  methods: {
    onmouseoverHandler,
    onmouseoutHandler,
    onmousedownHandler,
    toggleMode: function () {
      this.mode = (this.mode != 'elder') ? 'elder' : 'family'
    },
    highlightPhoto: function ({highlighted}) {
      this.highlighted = highlighted
    },
    selectPhoto: function ({selected, toggle}) {
      if (toggle) {
        selected = !this.selected
      }

      if (!selected) {
        this.selected = false
        return window.targetPhoto = null
      }

      if (!window.candidatePhoto) return setTimeout(() => { selectPhoto(selected) }, 150)
      window.targetPhoto = window.candidatePhoto
      this.selected = true
    },
    resetPhoto: function () {
      this.entry.backgroundPositionX = 'center'
      this.entry.backgroundPositionY = 'center'
      this.entry.backgroundSize = 'cover'
      this.mode = 'elder'
    },
  },
  mounted() {
    const self = this
    Event.$on(this.entry.uuid, function(payload){
      // console.log(`>>>payload from ${self.entry.uuid}`, payload)
      switch(payload.action) {
        case 'photo-manipulation':
          const {attribute, offset, defaultVal, label} = payload.data
          const currentValue = getSize(self.entry[attribute], defaultVal)
          return self.entry[attribute] = (currentValue - offset) + "px"

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
    }
  },
  mounted() {
    this.yearbook = yearbook.map(entry => ({...entry, backgroundSize: 'cover', backgroundPositionX: 'center', backgroundPositionY: 'center', active: 'elderPhoto'}))

    // selectPhotos();

// background-size: 1100px;
// background-position-x: -570px;
// background-position-y: -180px;    

    document.onkeydown = function(evt) {
        evt = evt || window.event;
        const offset = (evt.shiftKey && evt.ctrlKey) ? 500 : (evt.ctrlKey) ? 50 : (evt.shiftKey) ? 100 : 15

        // if (evt.ctrlKey && evt.keyCode == 90) {
        //     alert("Ctrl-Z");
        // }
        // else if (evt.keyCode == 84) { // t > set target photo
        //   selectPhoto(!window.targetPhoto)
        // }
        if (false) {}
        else if (evt.keyCode == 84) { 
          const dataId = window.candidatePhoto.getAttribute("data-id")
          Event.$emit(dataId, {action: 'selectPhoto', type: 'key-code-t', data: {toggle: true}}) 
        }
        else if (evt.keyCode == 82) { 
          const dataId = window.targetPhoto.getAttribute("data-id")
          Event.$emit(dataId, {action: 'resetPhoto'}) 
        }
        else if (evt.keyCode == 188) { zoomOut(evt, {offset}) }
        else if (evt.keyCode == 190) { zoomIn(evt, {offset}) }
        else if (evt.keyCode == 87)  { scrollUp(evt, {offset}) }
        else if (evt.keyCode == 83)  { scrollDown(evt, {offset}) }
        else if (evt.keyCode == 65)  { scrollLeft(evt, {offset}) }
        else if (evt.keyCode == 68)  { scrollRight(evt, {offset}) }
        else {
          console.log(">>>evt.keyCode", evt.keyCode)
        }
    };
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
