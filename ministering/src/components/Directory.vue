<template>
  <div class="directory">
    <autocomplete v-model="autocompleteValue" :source="availableNames"
      @input="selectedHandler"
    >
    </autocomplete>

    <div class="supportedSortOptions-label">Sort Options:</div>
    <input v-model="sortOptionsInput" type="text" placeholder="name"><span class="supportedSortOptions">({{supportedSortOptions.join(",")}})</span>
    <ul>
      <li v-for="entry in selectedNames" :key="entry.id">
        <PersonContactInfo :entry="entry" inline-template>
          <div class="person-contact-info">
            <div @click="toggleEdit" class="edit-mode"></div>

            <h3 class="name">{{entry.name}}</h3>
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
    this.phone = this.entry.phone
    this.email = this.entry.email
  }
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
      supportedSortOptions: 'name,phone,email,address,district,street'.split(/,/)
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

      // this.valuesOnly = this.selectedNames.map(entry => {
      //   const keys = Object.keys(entry)
      //   return keys.map(key => entry[key]).join("	")
      // }).join("\n")
      // 
      // $vm0.valuesOnly = $vm0.selectedNames.map(entry => {                               //
      //   const keys = Object.keys(entry)
      //   return keys.map(key => entry[key].toString().replace(/[\r\n]/g, ' ')).join("	")
      // }).join("\n")


      document.querySelector(".autocomplete .autocomplete--clear").click();
      document.querySelector(".autocomplete input[placeholder='Search']").focus();
    },
  },
  mounted() {
    const self = this
    this.names = directoryNames.map((entry, index) => {
      const md = entry.district.match(/(\d+)-(.*)/)
      const [all, district, street] = (md) ? md : ['', '99', '']
      return {id: index+1, ...entry, district, street}
    })
    this.availableNameIds = this.names.map(entry => entry.id)

    const autocompleteInput = document.querySelector(".autocomplete input[placeholder='Search']")
    autocompleteInput.addEventListener("keydown", function(evt){
      if (evt.keyCode === 13) {
        if (document.querySelectorAll(".autocomplete .autocomplete__results__item").length > 0) {
          const name = document.querySelectorAll(".autocomplete .autocomplete__results__item")[0].innerText
          self.autocompleteValue = self.names.filter(entry => entry.name === name)[0].id
          self.selectedHandler()
        }
      }
    });
  },
  watch: {
    // $vm0.selectedNameIds = "468,112,186,228,209,153,337,456,354,479,271,463,189,474,307,161,178,516,127,407,243,330".split(",").map(entry => parseInt(entry))
    selectedNameIds: function(_new, _old) {
      this.valuesOnly = _new.map(id => this.names.filter(entry => entry.id === id)[0]).sort(sortEntries(this.sortOptions)).map(entry => {
        const keys = Object.keys(entry).filter(key => !["id", "district", "street"].includes(key))
        const values = keys.map(key => entry[key].toString().replace(/[\r\n]/g, ' '))
        values.push(`${entry.district}-${entry.street}`)
        return values.join("	")
      }).join("\n")
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
</style>
