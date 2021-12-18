<template>
  <div class="directory">
    <autocomplete v-model="autocompleteValue" :source="availableNames"
      @input="selectedHandler"
    >
    </autocomplete>

    <div>{{hoverNameIdx}}</div>

    <div>
      <button @click="addAllNames">All Contactable</button>
    </div>
    
    <div>
      <button @click="addAllDistrict(1)">District 1</button>
      <button @click="addAllDistrict(2)">District 2</button>
      <button @click="addAllDistrict(3)">District 3</button>
    </div>

    <div>
      <button @click="addAllEqPresNames">All EQ Pres</button>
    </div>

    <div>
      <button @click="addAllEqNames">All EQ</button>
      <button @click="addAllEqInAuxNames">All EQ in Aux</button>
      <button @click="addAllRsNames">All RS</button>
      <button @click="addAllEqRsNames">All Adults</button>
    </div>

    <div>
      <button @click="addAllYmNames">All YM</button>
      <button @click="addAllYwNames">All YW</button>
      <button @click="addAllYmYwNames">All Youth</button>
    </div>

    <div class="supportedSortOptions-label">Sort Options:</div>
    <input v-model="sortOptionsInput" type="text" placeholder="name" @focus="inputting=true" @blur="inputting=false"><span class="supportedSortOptions">({{supportedSortOptions.join(",")}})</span>
    <ul>
      <li v-for="entry in selectedNames" :key="entry.id">
        <PersonContactInfo :entry="entry" inline-template>
          <div :class="classNames">
            <h3 class="name" :class="nameClassNames">{{entry.name}}</h3>
            <div class="phone"><span class="label">Phone: </span><span class="value"><a :href="formattedPhone">{{phone}}</a></span></div>
            <div class="email"><span class="label">Email: </span><span class="value"><a :href="formattedEmail">{{email}}</a></span></div>
            <div class="address"><span class="label">Address: </span><span class="district">({{entry.district}}{{(entry.companionshipId) ? `, ${entry.companionshipId}` : ''}}, {{entry.neighborhood}})</span>&nbsp;<span class="value" v-html="entry.address"></span></div>
            <div><span class="label">&nbsp;</span></div>
            <div class="actionIcons">
              <div @click="$parent.removeName(entry.id)" class="icon trash-mode"></div>
              <div @click="toggleEdit" class="icon edit-mode"></div>
            </div>
            
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

    <div>
      <div style="display: inline-block;">
        <router-link :to="queueTextMessageLink">Queue Text Message</router-link>
        <br>
        <textarea id="values-only" v-model="valuesOnly" name="" cols="30" rows="10"></textarea>
      </div>

      <div style="display: inline-block;">
        Email Addresses
        <br>
        <textarea id="email-values-only" v-model="emailValuesOnly" name="" cols="30" rows="10"></textarea>
      </div>

      <div style="display: inline-block;">
        Phone Numbers
        <br>
        <textarea id="email-values-only" v-model="phoneNumberValuesOnly" name="" cols="30" rows="10"></textarea>
      </div>
    </div>
  
  </div>
</template>

<script>
import Vue from 'vue'
import directoryNames from '../../../directory-contact-info.json'
import eqNames from '../../../eq-cleaned.json'
import eqPresNames from '../../../eq-pres-members.json'
import eqInAuxNames from '../../../eq-members-with-aux-positions.json'
import eqNamesDistrict01 from '../../../ministering-assignments-district-01.json'
import eqNamesDistrict02 from '../../../ministering-assignments-district-02.json'
import eqNamesDistrict03 from '../../../ministering-assignments-district-03.json'
const eqNamesDistricts = {
  1: eqNamesDistrict01, 
  2: eqNamesDistrict02, 
  3: eqNamesDistrict03, 
  all: eqNamesDistrict01.concat(eqNamesDistrict02).concat(eqNamesDistrict03),
}

import rsNames from '../../../rs-cleaned.json'
import ymNames from '../../../ym-cleaned.json'
import ywNames from '../../../yw-cleaned.json'
import doNotContact from '../../../do-not-contact.json'
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
    },
  },
  mounted(){
    const self = this
    this.phone = this.entry.phone
    this.email = this.entry.email

    // this.$set(this.entry, 'b', 2)
  },
})

const sortEntries = (field='name') => {
  if (!field) return (n1, n2) => 0

  if (typeof field === 'object') {
    return (n1, n2) => {
      return field.reduce((tres, f) => {
        if (tres === 0)
          return n1[f].toString().localeCompare(n2[f].toString())
        else
          return tres
      }, 0)
    }
  } else 
    // TODO; some comparisons may not include matching fields
    console.warn(">>>WARN: some comparisons may not include matching fields")

    return (n1, n2) => (n1[field] || "").toString().localeCompare((n2[field] || "").toString())
};

const focusOnFilter = () => {
  document.querySelector(".autocomplete .autocomplete--clear").click();
  document.querySelector(".autocomplete input[placeholder='Search']").focus();
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
      sortOptionsInput: '',
      supportedSortOptions: 'name,phone,email,address,district,neighborhood,companionshipId'.split(/,/),
      hoverNameIdx: -1,
      states: [],
      stateIdx: -1,
      restoring: false,
      inputting: false,
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
      const _names = this.names.map(entry => {
        const { companionshipId } = eqNamesDistricts.all.find(_entry => _entry.name === entry.name) || {}
        return (companionshipId) ? {...entry, companionshipId: `comp-${companionshipId.toString().padStart(2, '0')}`} : entry
      })
      return this.selectedNameIds.map(id => _names.filter(entry => entry.id === id)[0]).sort(sortEntries(this.sortOptions))
    },
    valuesOnly: function(){
      return this.selectedNameIds.map(id => this.names.filter(entry => entry.id === id)[0]).sort(sortEntries(this.sortOptions)).map(entry => {
        const keys = Object.keys(entry).filter(key => !["id", "district", "neighborhood"].includes(key))
        const values = keys.map(key => (entry[key]) ? entry[key].toString().replace(/[\r\n]/g, ' ') : entry[key])
        values.push(`${entry.district}-${entry.neighborhood}`)
        return values.join("	")
      }).join("\n")
    },
    emailValuesOnly: function(){
      return this.selectedNameIds.map(id => this.names.filter(entry => entry.id === id)[0]).sort(sortEntries('email')).map(entry => entry.email).join("\n")
    },
    phoneNumberValuesOnly: function(){
      return this.selectedNameIds.map(id => this.names.filter(entry => entry.id === id)[0]).sort(sortEntries('phone')).map(entry => entry.phone).join("\n")
    },
    queueTextMessageLink: function(){
      let stagedIds = this.selectedNames.filter(entry => {
        return entry.selected
      }).map(entry => entry.id)
      stagedIds = (stagedIds.length > 0) ? stagedIds : this.selectedNameIds
      
      return { name: 'MassPrivatePersonalText', params: { ids: stagedIds } }
    }
  },
  methods: {
    removeName: function(id){
      this.selectedNameIds = this.selectedNameIds.filter(entryId => entryId != id)
    },
    addAllNames: function(){
      const _eqNames = eqNames.map(entry => entry.name)
      const _rsNames = rsNames.map(entry => entry.name)
      const _ymNames = ymNames.map(entry => entry.name)
      const _ywNames = ywNames.map(entry => entry.name)
      const _allNames = _eqNames.concat(_rsNames).concat(_ymNames).concat(_ywNames)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (_allNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    addAllDistrict: function(idx){
      const targetDistrict = `district-${idx.toString().padStart(2, '0')}`
      // const checkEntry = eqNames[1]
      // console.log(">>>eqNames", checkEntry, {targetDistrict, 'entry.district': checkEntry.district, chk: eqNames[0].district === targetDistrict})

      const _eqNamesInDistrict = eqNamesDistricts[idx].map(entry => entry.name)
      const _eqNames = eqNames.map(entry => entry.name)
      const _doNotContact = doNotContact.map(entry => entry.name)
      let _selectedNames = this.names.filter(entry => (_eqNames.includes(entry.name) && _eqNamesInDistrict.includes(entry.name) && !_doNotContact.includes(entry.name)))
        .map(entry => {
          const assignment = eqNamesDistricts[idx].find(_entry => _entry.name === entry.name)
          const payload = {...entry, companionshipId: `comp-${assignment.companionshipId.toString().padStart(2, '0')}`}
          // console.log(">>>payload", payload)
          return payload
        })

      if (!this.sortOptions)
        _selectedNames = _selectedNames
          .sort(sortEntries('companionshipId'))
          // .sort(sortEntries('name'))

      this.selectedNameIds = _selectedNames.map(entry => entry.id)
    },
    addAllEqPresNames: function(){
      const _eqPresNames = eqPresNames.map(entry => entry.name)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (_eqPresNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    addAllEqNames: function(){
      const _eqNames = eqNames.map(entry => entry.name)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (_eqNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    addAllEqInAuxNames: function(){
      const _eqInAuxNames = eqInAuxNames.map(entry => entry.name)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (_eqInAuxNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    addAllRsNames: function(){
      const _rsNames = rsNames.map(entry => entry.name)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (_rsNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    addAllEqRsNames: function(){
      const _eqNames = eqNames.map(entry => entry.name)
      const _rsNames = rsNames.map(entry => entry.name)
      const adultNames = _eqNames.concat(_rsNames)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (adultNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    addAllYmNames: function(){
      const _ymNames = ymNames.map(entry => entry.name)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (_ymNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    addAllYwNames: function(){
      const _ywNames = ywNames.map(entry => entry.name)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (_ywNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    addAllYmYwNames: function(){
      const _ymNames = ymNames.map(entry => entry.name)
      const _ywNames = ywNames.map(entry => entry.name)
      const youthNames = _ymNames.concat(_ywNames)
      const _doNotContact = doNotContact.map(entry => entry.name)
      this.selectedNameIds = this.names.filter(entry => (youthNames.includes(entry.name) && !_doNotContact.includes(entry.name))).map(entry => entry.id)
    },
    sendTextMessage: function(){
      // console.log(">>>this.selectedNameIds", this.selectedNameIds.length, this.hoverNameIdx)
      if (this.inputting || this.selectedNameIds.length < 1) return

      this.$router.push(this.queueTextMessageLink)
    },
    selectedHandler: function() {
      let fndIndex = -1
      for (let i=0; i<this.names.length; i++) {
        if (this.names[i].id == this.autocompleteValue) {
          fndIndex = i
          this.names[i].selected = false
          this.names[i].hovered = false
          this.selectedNameIds.push(this.names[i].id)
        }
      }
      if (fndIndex > -1) {
        this.selectedNameIds = this.selectedNameIds
        // this.availableNameIds = this.names.filter(entry => !this.selectedNameIds.includes(entry.id)).map(entry => entry.id)
        // this.availableNameIds = this.names.sort((n1, n2) => n1.name.localeCompare(n2.name)).filter(entry => !this.selectedNameIds.includes(entry.id)).map(entry => entry.id)
      }

      focusOnFilter()
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
      // console.log(">>>select", entryIdx, this.names[entryIdx].selected)
      if (this.names[entryIdx]) this.names[entryIdx].selected = !this.names[entryIdx].selected
    },
    restoreState: function() {
      const state = JSON.parse(this.states[this.stateIdx])
      Object.keys(state).forEach(key => {
        this[key] = state[key]
      })
      this.restoring = false
    },
    nextState: function() {
      // console.log(">>>this.stateIdx [1]", this.stateIdx)
      if (this.stateIdx >= this.states.length-1) return

      this.restoring = true
      this.hoverNameIdx = -1
      this.stateIdx += 1
      // console.log(">>>this.stateIdx [2]", this.stateIdx)
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

      // if (stagedIds.length === 0) stagedIds = [this.selectedNameIds[this.hoverNameIdx]]

      // const entryId = stagedIds[0]
      // const entryIdx = this.selectedNameIds.findIndex(id => id == entryId)

      this.selectedNameIds = this.selectedNameIds.filter(id => !stagedIds.includes(id))

      if (this.hoverNameIdx >= this.selectedNameIds.length) this.hoverNameIdx = this.selectedNameIds.length - 1

      // this.hoverNameIdx = -1
      // this.$nextTick(() => { this.hoverNameIdx = entryIdx })
    },
  },
  mounted() {
    const self = this
    this.names = directoryNames.map((entry, index) => {
      const md = entry.district.match(/^(district-.*)/)
      const [all, district] = (md) ? md : ['', '99', '']
      return {id: index+1, ...entry, district, neighborhood: entry.neighborhood, hovered: false, selected: false}
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

    autocompleteInput.addEventListener("focus", (evt) => {
      self.inputting = true
    });
    autocompleteInput.addEventListener("blur", (evt) => {
      self.inputting = false
    });
    

    document.onkeydown = function(evt) {
      return true

      if (![85, 82].includes(evt.keyCode)) self.lastRestoreAction = null
      
      switch(evt.keyCode) {
        case 74: { self.navDown(); break; }
        case 75: { self.navUp(); break; }
        case 88: { self.select(); break; }
        case 68: { self.saveState({truncate: true}); self.removeSelected(); break; }
        case 85: { self.prevState(); break; }
        case 82: { if (evt.ctrlKey) self.nextState(); break; }
        case 84: { self.sendTextMessage(); break; }
        default: 
          // console.log(">>>evt.keyCode", evt.keyCode)
          // ctrlKey
      }
    };

    focusOnFilter()
  },
  watch: {
    inputting: function(_new) {
      // console.log(`>>>inputting ${_new}`)
    },
    // $vm0.selectedNameIds = "1,468,112,186,228,209,153,337,456,354,479,271,463,189,474,307,161,178,516,127,407,243,330".split(",").map(entry => parseInt(entry))
    sortOptionsInput: function(_new, _old) {
      if (_new != _old) this.hoverNameIdx = -1
    },
    selectedNameIds: function(_new, _old) {
      this.availableNameIds = this.names.filter(_entry => !_new.includes(_entry.id)).map(_entry => {
        return _entry.id
      })
    },
    hoverNameIdx: function(_new, _old) {
      if (this.restoring) return

      // console.log(">>>currEntry [1]", _new, _old)
      const prevEntry = this.names.find(_entry => (this.selectedNames[_old] && this.selectedNames[_old].id) === _entry.id)
      const currEntry = this.names.find(_entry => (this.selectedNames[_new] && this.selectedNames[_new].id) === _entry.id)

      // console.log(">>>currEntry [2]", _new, currEntry)
      if (prevEntry) prevEntry.hovered = false
      if (currEntry) currEntry.hovered = true
      // console.log(">>>_new:hoverNameIdx", _new)
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

  div.actionIcons {
    position: relative;
    margin-left: 2em;
  }

  div.icon {
    position: relative;
    height: 20px;
    width: 20px;
    cursor: pointer;
    margin-left: 10px;

  }
  div.edit-mode {
    background: url('../assets/notes-icon.png') center / cover;
  }
  div.trash-mode {
    background: url('../assets/trash-icon.png') center / cover;
  }

  .values-only .entry div {
    display: inline-block;
  }

  .person-contact-info .name { width: 200px; }
  .person-contact-info .phone { width: 200px; }
  .person-contact-info .email { width: 250px; }
  .person-contact-info .address { width: 350px; }

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
