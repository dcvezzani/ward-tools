<template>
  <div class="yearbook">
    <YearbookEntry v-for="entry in yearbook" :key="entry.uuid" :entry="entry" class="yearbook-entry" inline-template>
      <div @mouseover="onmouseoverHandler" @mousedown="onmousedownHandler" @mouseout="onmouseoutHandler" v-if="mode == 'elder'" @click="mode = 'family'" class="photo" :style="elder"><span class="label"><span class="text truncate">{{ entry.name }}</span></span></div>
      <div @mouseover="onmouseoverHandler" @mousedown="onmousedownHandler" @mouseout="onmouseoutHandler" v-else class="photo" @click="mode = 'elder'" :style="family"><span class="label"><span class="text truncate">{{ entry.name }}</span></span></div>
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
  evt.target.classList.add("selected");
  window.candidatePhoto = evt.target
}

const onmouseoutHandler = (evt) => {
  if (window.targetPhoto) return
  evt = evt || window.event;
  evt.target.classList.remove("selected");
}

const onmousedownHandler = (evt) => {
  evt = evt || window.event;
  // console.log(">>>trace 1")
  if (window.targetPhoto) window.targetPhoto.classList.remove("selected")
  window.candidatePhoto = evt.target
  selectPhoto(true)
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
*/

const getSize = (targetElement, defaultValue) => {
  return (targetElement.match(/\d+px/)) ? parseInt(targetElement.replace(/px/, '')) : defaultValue
}

Vue.component('YearbookEntry', {
  props:['entry'],
  data() {
    return {
      mode: "elder",
    }
  },
  computed: {
    elder: function() {
      return "background: url('" + this.entry.elderPhoto + "') center / cover no-repeat rgb(255, 255, 255); display: inline-block; height: 200px; width: 200px;"
    },
    family: function() {
      return "background: url('" + this.entry.familyPhoto + "') center / cover no-repeat rgb(255, 255, 255); display: inline-block; height: 200px; width: 200px;"
    },
  },
  methods: {
    onmouseoverHandler,
    onmouseoutHandler,
    onmousedownHandler,
  },
  mounted() {
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
        const backgroundSize = getSize(window.candidatePhoto.style.backgroundSize, window.candidatePhoto.offsetWidth)

        if (evt.ctrlKey && evt.keyCode == 90) {
            alert("Ctrl-Z");
        }
        else if (evt.keyCode == 84) { // t > set target photo
          selectPhoto(!window.targetPhoto)
        }
        else if (evt.keyCode == 82) { // t > set target photo
          if (!window.targetPhoto) return
          window.targetPhoto.style.backgroundSize = "cover"
          window.targetPhoto.style.backgroundPosition = "center"
        }
        else if (evt.keyCode == 188) { // zoom out by offset
          if (!window.targetPhoto) return
          window.targetPhoto.style.backgroundSize = (backgroundSize - offset) + "px"
        }
        else if (evt.keyCode == 190) { // zoom in by offset
          if (!window.targetPhoto) return
          window.targetPhoto.style.backgroundSize = (backgroundSize + offset) + "px"
        }
        else if (evt.keyCode == 87) { // scroll up by offset
          if (!window.targetPhoto) return
          let backgroundPositionY = getSize(window.targetPhoto.style.backgroundPositionY, 0)
          window.targetPhoto.style.backgroundPositionY = (backgroundPositionY - offset) + "px"
        }
        else if (evt.keyCode == 83) { // scroll down by offset
          if (!window.targetPhoto) return
          let backgroundPositionY = getSize(window.targetPhoto.style.backgroundPositionY, 0)
          window.targetPhoto.style.backgroundPositionY = (backgroundPositionY + offset) + "px"
        }
        else if (evt.keyCode == 65) { // scroll left by offset
          if (!window.targetPhoto) return
          let backgroundPositionX = getSize(window.targetPhoto.style.backgroundPositionX, 0)
          window.targetPhoto.style.backgroundPositionX = (backgroundPositionX - offset) + "px"
        }
        else if (evt.keyCode == 68) { // scroll right by offset
          if (!window.targetPhoto) return
          let backgroundPositionX = getSize(window.targetPhoto.style.backgroundPositionX, 0)
          window.targetPhoto.style.backgroundPositionX = (backgroundPositionX + offset) + "px"
        }
        else {
          console.log(">>>evt.keyCode", evt.keyCode)
        }
    };
  },
}
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
