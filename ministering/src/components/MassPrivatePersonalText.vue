<template>
  <div class="columns mass-private-personal-text">
    <div class="column is-one-quarter">
      <div>
        {{ $route.params }}
      </div>
      <div>
        {{ namePhoneEntries }}
      </div>

      <div>
        <textarea v-model="message" id="textMessage" name="textMessage" cols="30" rows="10"></textarea>
      </div>

      <div>
        <button @click="sendText">Send Text</button>
      </div>
   
    </div>
    <div class="column is-half">
      <div class="targeted-texts columns">
        <div class="column is-one-quarter">
          <ul>
              <li v-for="entry in selectedNames" :key="entry.id" :entry="entry" class="text-message-recipient"> <a href="javascript:void(0)" @click="loadRecipient(entry)">{{entry.name}}</a> </li>
          </ul>
        </div>

        <div class="column">
          <TextMessageRecipient v-if="selectedEntry" :entry="selectedEntry" inline-template>
            <div class="text-message-recipient">
              <div>
                {{ entry.phone }}, {{ entry.lastName }}
              </div>

              <div>
                <textarea v-model="entry.message" id="textMessage" name="textMessage" cols="30" rows="10"></textarea>
              </div>

              <div>
                <button @click="sendText">Send Text</button>
              </div>
                    
            </div>
          </TextMessageRecipient>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import Vue from 'vue'
import directoryNames from '../../../directory-contact-info.json'

// Vue.component('CallingPosition', {
//   name: 'CallingPosition',
//   props: ['positions'],
//   data: function () {
//     return {
//     }
//   },
// })

const lastName = (name) => {
  return name.split(/,/)[0]
};

const cleanPhone = (phone) => {
  return (phone || '').replace(/\D/g, '')
};

function sendText() {
  const ans = confirm(`Are you sure you want to send text messages to ${this.namePhoneEntries.length} recipient(s)?`);
  // if (['yes', 'y', 'Y'].includes(ans)) {
  if (ans === true) {
    fetch('http://localhost:3000/send-text', {
      method: "POST",
      headers: {'content-type': 'application/json; charset=UTF-8'},
      body: JSON.stringify({recipients: this.namePhoneEntries, message: this.message}),
    })
    .then(data => data.json())
    .then(res => console.log(res))
    .catch(err => console.error(err))
  }
}

Vue.component('TextMessageRecipient', {
  props:['entry'],
  data() {
    return {
    }
  },
  computed: {
    message: function() {
      return this.entry.message
    },
    namePhoneEntries: function() {
      const {phone, lastName} = this.entry
      return [[phone, lastName].join(",")]
    },
  },
  methods: {
    sendText,
  },
  mounted() {
    this.entry.message = `Brother ${this.entry.lastName},\n\nThis is a test.\n\nCheers,\n--- Bro. Vezzani`
    this.sendText = sendText.bind(this)
  },
  watch: {
    entry: function() {
      if (this.entry.message.length === 0) {
        this.entry.message = `Brother ${this.entry.lastName},\n\nThis is a test.\n\nCheers,\n--- Bro. Vezzani`
      }
    },
  },
})

export default {
  name: 'MassPrivatePersonalText',
  components: { },
  props: ['person'],
  computed: {
    selectedNameIds: function(){
      return this.$route.params.ids
    },
    selectedNames: function(){
      return (this.names.length === 0 || !this.selectedNameIds) ? [] : this.selectedNameIds.map(id => {
        // console.log(">>>trace 1")
        return this.names.find(entry => entry.id === id)
      })
    },
    namePhoneEntries: function(){
      return this.selectedNames.map(entry => [entry.phone, entry.lastName].join(","))
    },
  },
  data() {
    return {
      names: [],
      asdf: false,
      message: null,
      selectedEntry: null,
    }
  },
  methods: {
    loadRecipient: function(entry) {
      this.selectedEntry = entry;
    },
    sendText,
  },
  mounted() {
    this.names = directoryNames.map((entry, index) => {
      const md = entry.district.match(/(\d+)-(.*)/)
      const [all, district, street] = (md) ? md : ['', '99', '']
      const message = ""
      return {id: index+1, ...entry, phone: cleanPhone(entry.phone), lastName: lastName(entry.name), district, street, message}
    })

    this.message = (this.namePhoneEntries.length > 1 || this.selectedNames.length < 1)
      ? 'Brother ${name},\n\nThis is a test.\n\nCheers,\n--- Bro. Vezzani'
      : `Brother ${this.selectedNames[0].lastName},\n\nThis is a test.\n\nCheers,\n--- Bro. Vezzani`

    this.selectedEntry = this.selectedNames[0]
    this.sendText = sendText.bind(this)
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style >
  .mass-private-personal-text {
    padding: 10px 0;
    width: 100%;
  }
  h3 {
    padding: 0;
    margin: 0;
  }
  .columns .column {
  }
  .targeted-texts {
    width: 100%;
  }
  .xxx.columns .column {
    border: 1px solid orange;
  }
</style>
