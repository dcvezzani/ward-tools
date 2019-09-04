<template>
  <div class="directory">
    <autocomplete v-model="autocompleteValue" :source="availableNames"
      @input="selectedHandler"
    >
    </autocomplete>

    <div>{{hoverNameIdx}}</div>

    <div class="supportedSortOptions-label">Sort Options:</div>
    <input v-model="sortOptionsInput" type="text" placeholder="name"><span class="supportedSortOptions">({{supportedSortOptions.join(",")}})</span>
    <ul>
      <li v-for="entry in selectedNames" :key="entry.id">
        <PersonContactInfo :entry="entry" inline-template>
          <div :class="classNames">
            <div @click="toggleEdit" class="edit-mode"></div>

            <h3 class="name" :class="nameClassNames">{{entry.id}}, {{entry.name}}</h3>
            <div class="phone"><span class="label">Phone: </span><span class="value"><a :href="formattedPhone">{{phone}}</a></span></div>
            <div class="email"><span class="label">Email: </span><span class="value"><a :href="formattedEmail">{{email}}</a></span></div>
            <div class="address"><span class="label">Address: </span>(<span class="district">{{entry.district}}-{{entry.street}}</span>) </span><span class="value" v-html="entry.address"></span></div>
            <div v-if="mode == 'edit'" class="form-actions">
              <div class="field">
                phone:
                <input v-model="phone" class="input" type="text" placeholder="phone">
              </div>
              <div class="field">
                email: 
                <input v-model="email" class="input" type="text" placeholder="email">
              </div>
            </div>
          </div>
        </PersonContactInfo>
      </li>
    </ul>

    <textarea id="values-only" v-model="valuesOnly" name="" cols="30" rows="10"></textarea>
  
  </div>
</template>

<script>
import Vue from 'vue'
import directoryNames from '../../../directory-contact-info.json'
import Autocomplete from 'vuejs-auto-complete'

Vue.component('PersonContactInfo', {
  props:['entry'],
  data() {
    return {
      phone: "",
      email: "",
      mode: "",
    }
  },
  computed: {
    classNames: function() {
      const hovered = (this.entry && this.entry.hovered) ? 'hovered' : ''
      return ['person-contact-info', hovered]
    },
    nameClassNames: function() {
      const selected = (this.entry && this.entry.selected) ? 'selected' : ''
      return [selected]
    },
    formattedPhone: function() {
      return `tel:${this.phone}`
    },
    formattedEmail: function() {
      return `mailto:${this.email}`
    },
  },
  methods: {
    toggleEdit: function(){
      this.mode = (this.mode == 'edit') ? 'view' : 'edit'
    }
  },
  mounted(){
    const self = this
    this.phone = this.entry.phone
    this.email = this.entry.email

    // this.$set(this.entry, 'b', 2)
  },
})

const sortEntries = (field="name") => {
  if (!field) return (n1, n2) => 0

  if (typeof field === 'object') {
    return (n1, n2) => {
      return field.reduce((tres, f) => {
        if (tres === 0)
          return n1[f].localeCompare(n2[f])
        else
          return tres
      }, 0)
    }
  } else 
    return (n1, n2) => n1[field].localeCompare(n2[field])
};

export default {
  name: 'Directory',
  components: {autocomplete: Autocomplete},
  props: {
    msg: String
  },
  data() {
    return {
      names: [],
      availableNameIds: [],
      selectedNameIds: [],
      autocompleteValue: '',
      valuesOnly: '',
      sortOptionsInput: '',
      supportedSortOptions: 'name,phone,email,address,district,street'.split(/,/),
      hoverNameIdx: -1,
      states: [],
      stateIdx: -1,
      restoring: false,
      lastRestoreAction: null,
    }
  },
  computed: {
    sortOptions: function(){
      if (this.sortOptionsInput.length === 0) return null
      let soptions = this.sortOptionsInput.split(/ *, */)
      soptions = soptions.filter(o => this.supportedSortOptions.includes(o))
      return (soptions.length === 1) ? soptions[0] : soptions
    },
    availableNames: function(){
      return this.availableNameIds.filter(entry => entry != null).map(id => this.names.filter(entry => entry.id === id)[0])
    },
    selectedNames: function(){
      return this.selectedNameIds.map(id => this.names.filter(entry => entry.id === id)[0]).sort(sortEntries(this.sortOptions))
    },
  },
  methods: {
    selectedHandler: function(selectedValue) {
      let fndIndex = -1
      for (let i=0; i<this.names.length; i++) {
        if (this.names[i].id == this.autocompleteValue) {
          fndIndex = i
          this.selectedNameIds.push(this.names[i].id)
        }
      }
      if (fndIndex > -1) {
        this.selectedNameIds = this.selectedNameIds
        this.availableNameIds = this.names.filter(entry => !this.selectedNameIds.includes(entry.id)).map(entry => entry.id)
        // this.availableNameIds = this.names.sort((n1, n2) => n1.name.localeCompare(n2.name)).filter(entry => !this.selectedNameIds.includes(entry.id)).map(entry => entry.id)
      }

      document.querySelector(".autocomplete .autocomplete--clear").click();
      document.querySelector(".autocomplete input[placeholder='Search']").focus();
    },
    navDown: function() {
      this.hoverNameIdx += (this.hoverNameIdx < this.selectedNameIds.length - 1) ? 1 : 0
    },
    navUp: function() {
      this.hoverNameIdx -= (this.hoverNameIdx > 0) ? 1 : 0
    },
    select: function() {
      const entryId = this.selectedNameIds[this.hoverNameIdx]
      const entryIdx = this.names.findIndex(entry => entry.id == entryId)
      this.names[entryIdx].selected = !this.names[entryIdx].selected
    },
    restoreState: function() {
      const state = JSON.parse(this.states[this.stateIdx])
      Object.keys(state).forEach(key => {
        this[key] = state[key]
      })
      this.restoring = false
    },
    nextState: function() {
      console.log(">>>this.stateIdx [1]", this.stateIdx)
      if (this.stateIdx >= this.states.length-1) return

      this.restoring = true
      this.hoverNameIdx = -1
      this.stateIdx += 1
      console.log(">>>this.stateIdx [2]", this.stateIdx)
      this.$nextTick(() => this.restoreState())
      this.lastRestoreAction = 'nextState'
    },
    prevState: function() {
      if (this.stateIdx < 1) return

      if (this.lastRestoreAction === null) {
        this.saveState()
        this.stateIdx -= 1
      }

      this.restoring = true
      this.hoverNameIdx = -1
      this.stateIdx -= 1
      this.$nextTick(() => this.restoreState())
      this.lastRestoreAction = 'prevState'
    },
    saveState: function(options) {
      const {truncate} = {truncate: false, ...options}
      if (truncate) {
        this.states = this.states.slice(0,this.stateIdx)
      }

      const snapshot = Object.keys(this.$data).filter(key => !['stateIdx', 'states', 'restoring', 'lastRestoreAction'].includes(key)).reduce((map, key) => {
        map[key] = this[key]
        return map
      }, {})

      this.states.push(JSON.stringify(snapshot))
      this.stateIdx = this.states.length
    },
    removeSelected: function() {
      if (this.selectedNameIds.length < 1 || this.hoverNameIdx < 0) return

      let stagedIds = this.selectedNames.filter(entry => {
        return entry.selected
      }).map(entry => entry.id)

      if (stagedIds.length === 0) stagedIds = [this.selectedNameIds[this.hoverNameIdx]]

      const entryId = stagedIds[0]
      const entryIdx = this.selectedNameIds.findIndex(id => id == entryId)

      this.selectedNameIds = this.selectedNameIds.filter(id => !stagedIds.includes(id))
      console.log(">>>entryIdx", entryIdx, this.selectedNameIds[entryIdx])

      this.hoverNameIdx = -1
      this.$nextTick(() => { this.hoverNameIdx = entryIdx })
    },
  },
  mounted() {
    const self = this
    this.names = directoryNames.map((entry, index) => {
      const md = entry.district.match(/(\d+)-(.*)/)
      const [all, district, street] = (md) ? md : ['', '99', '']
      return {id: index+1, ...entry, district, street, hovered: false, selected: false}
    })
    this.availableNameIds = this.names.map(entry => entry.id)

    const autocompleteInput = document.querySelector(".autocomplete input[placeholder='Search']")
    autocompleteInput.addEventListener("keydown", (evt) => {
      if (evt.keyCode === 13) {
        if (document.querySelectorAll(".autocomplete .autocomplete__results__item").length > 0) {
          const name = document.querySelectorAll(".autocomplete .autocomplete__results__item")[0].innerText
          self.autocompleteValue = self.names.filter(entry => entry.name === name)[0].id
          self.selectedHandler()
        }
      }
    });

    document.onkeydown = function(evt) {
      if (![85, 82].includes(evt.keyCode)) self.lastRestoreAction = null
      
      switch(evt.keyCode) {
        case 74: { self.navDown(); break; }
        case 75: { self.navUp(); break; }
        case 88: { self.select(); break; }
        case 68: { self.saveState({truncate: true}); self.removeSelected(); break; }
        case 85: { self.prevState(); break; }
        case 82: { if (evt.ctrlKey) self.nextState(); break; }
        default: 
          console.log(">>>evt.keyCode", evt.keyCode)
          // ctrlKey
      }
    };
  },
  watch: {
    // $vm0.selectedNameIds = "1,468,112,186,228,209,153,337,456,354,479,271,463,189,474,307,161,178,516,127,407,243,330".split(",").map(entry => parseInt(entry))
    selectedNameIds: function(_new, _old) {
      this.valuesOnly = _new.map(id => this.names.filter(entry => entry.id === id)[0]).sort(sortEntries(this.sortOptions)).map(entry => {
        const keys = Object.keys(entry).filter(key => !["id", "district", "street"].includes(key))
        const values = keys.map(key => (entry[key]) ? entry[key].toString().replace(/[\r\n]/g, ' ') : entry[key])
        values.push(`${entry.district}-${entry.street}`)
        return values.join("	")
      }).join("\n")
    },
    hoverNameIdx: function(_new, _old) {
      if (this.restoring) return

      console.log(">>>currEntry [1]", _new, _old)
      const prevEntry = this.names.find(_entry => this.selectedNameIds[_old] === _entry.id)
      const currEntry = this.names.find(_entry => this.selectedNameIds[_new] === _entry.id)
      console.log(">>>currEntry [2]", _new, currEntry)
      if (prevEntry) prevEntry.hovered = false
      if (currEntry) currEntry.hovered = true
    },
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
  .person-contact-info h3::after {
  }
  .person-contact-info h3 {
    font-size: small;
    display: inline-block;
    margin-right: 5px;
  }
  .person-contact-info div .label {
    font-weight: bold;
  }
  .person-contact-info div {
    font-size: small;
    display: inline-block;
  }

  .person-contact-info div:not(:first-of-type)::before {
  }

  .person-contact-info .field {
    margin-right: 1em;
  }
  div.edit-mode {
    position: relative;
    float: right;
    height: 20px;
    width: 20px;
    background: url('../assets/notes-icon.png') center / cover;
  }

  .values-only .entry div {
    display: inline-block;
  }

  .person-contact-info .name { width: 200px; }
  .person-contact-info .phone { width: 200px; }
  .person-contact-info .email { width: 250px; }
  .person-contact-info .address {  }

  .supportedSortOptions {
    margin-left: 1em;
  }
  .supportedSortOptions-label {
    margin-top: 1em;
  }
  .person-contact-info .selected {
    background-color: yellowgreen;
  }
  .person-contact-info.hovered {
    background-color: yellow;
  }
</style>
