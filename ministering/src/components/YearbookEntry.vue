<template>
  <div class="yearbook-entry">
      <div :data-id="entry.uuid" @mouseover="onmouseoverHandler" @mousedown="onmousedownHandler" @mouseout="onmouseoutHandler" @click="toggleMode" :class="classNames" :style="modeStyle"><span class="label"><span class="text truncate">{{ entry.name }}</span></span></div>
  </div>
</template>

<script>

const highlightPhoto = (evt, {highlighted, actionType}) => {
  const dataId = evt.target.getAttribute("data-id")
  if (dataId) {
    if (highlighted) {
      Event.$emit(dataId, {action: 'highlightPhoto', type: actionType, data: {highlighted: true, uuid: dataId}})
      window.candidatePhoto = evt.target
    }
    else {
      Event.$emit(dataId, {action: 'highlightPhoto', type: actionType, data: {highlighted, uuid: dataId}})
      if (!highlighted) window.candidatePhoto = null
    }
  }
}

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

const resetPhoto = () => {
  const dataId = window.targetPhoto.getAttribute("data-id")
  Event.$emit(dataId, {action: 'resetPhoto'}) 
}

const zoomOut = ({offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = window.targetPhoto.offsetWidth
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'zoomOut', data: {attribute: 'backgroundSize', offset, defaultVal, label: 'px'}})
}

const zoomIn = ({offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = window.targetPhoto.offsetWidth
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'zoomIn', data: {attribute: 'backgroundSize', offset: (-1)*offset, defaultVal, label: 'px'}})
}

const scrollUp = ({offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = 0
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'scrollUp', data: {attribute: 'backgroundPositionY', offset, defaultVal, label: 'px'}})
}

const scrollDown = ({offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = 0
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'scrollDown', data: {attribute: 'backgroundPositionY', offset: (-1)*offset, defaultVal, label: 'px'}})
}

const scrollLeft = ({offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = 0
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'scrollLeft', data: {attribute: 'backgroundPositionX', offset, defaultVal, label: 'px'}})
}

const scrollRight = ({offset}) => {
  if (!window.targetPhoto) return
  const defaultVal = 0
  Event.$emit(window.targetPhoto.getAttribute("data-id"), {action: 'photo-manipulation', type: 'scrollRight', data: {attribute: 'backgroundPositionX', offset: (-1)*offset, defaultVal, label: 'px'}})
}

const getSize = (targetElement, defaultValue) => {
  return (targetElement.match(/\d+px/)) ? parseInt(targetElement.replace(/px/, '')) : defaultValue
}

export default {
  name: 'YearbookEntry',
  props:['entry', 'photoModifications', 'isEditable'],
  data() {
    return {
      highlighted: false,
      selected: false,
    }
  },
  computed: {
    editable: function() {
      return (this.isEditable === "true")
    },
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
      if (!this.editable) return false
      this.photoModifications.active = (this.photoModifications.active != 'elderPhoto') ? 'elderPhoto' : 'familyPhoto'
    },
    highlightPhoto: function ({highlighted}) {
      if (!this.editable) return false
      this.highlighted = highlighted
    },
    selectPhoto: function ({selected}) {
      if (!this.editable) return false
      this.highlighted = false
      this.selected = selected
      // window.selectedPhotoUuid = this.entry.uuid
    },
    resetPhoto: function () {
      /* const photoModifications = this.photoModifications || {} */
      /* this.photoModifications.backgroundPositionX = photoModifications.backgroundPositionX || 'center' */
      /* this.photoModifications.backgroundPositionY = photoModifications.backgroundPositionY || 'center' */
      /* this.photoModifications.backgroundSize = photoModifications.backgroundSize || 'cover' */
      /* this.photoModifications.active = photoModifications.active || 'elderPhoto' */
    
      this.photoModifications.backgroundPositionX = 'center'
      this.photoModifications.backgroundPositionY = 'center'
      this.photoModifications.backgroundSize = 'cover'
      this.photoModifications.active = 'elderPhoto'
    },
    zoomIn,
    zoomOut,
    scrollUp,
    scrollDown,
    scrollLeft,
    scrollRight,
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

    Event.$on('selectPhotoHandler', function(payload){
      const { evt, data } = payload
      selectPhoto(evt, data)
    });
  },
  beforeDestroy() {
    Event.$off()
  },
}
</script>
