<template>
  <div class="mass-private-personal-text">
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
 
    <pre style="display: none;">
# send individual and personalize text messages
for line in {{ namePhoneEntries }}; do
  name="${line##*,}"
  phone="${line%%,*}"
  echo "Sending ${phone} > ${name}..."

# read -r -d '' MSG &lt;&lt;'EOF'   # everything is literal; don't resolve variables

read -r -d '' MSG &lt;&lt;EOF
Brother ${name},

This is a test message.

Where: 159 S Quivira Ln Vineyard, Utah 84059-5682
When: Thurs, 8/29/2019 @7pm

Cheers!

- Bro. Vezzani
EOF

  # osascript sendMessage.applescript "$phone" "$MSG"

  echo "$phone\n$MSG"
  sleep 2
done
    
    </pre>
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
        console.log(">>>trace 1")
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
      message: 'Brother ${name},\n\nThis is a test.\n\nCheers,\n--- Bro. Vezzani',
    }
  },
  methods: {
    sendText: function() {
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
    },
  },
  mounted() {
    const self = this
    this.names = directoryNames.map((entry, index) => {
      const md = entry.district.match(/(\d+)-(.*)/)
      const [all, district, street] = (md) ? md : ['', '99', '']
      return {id: index+1, ...entry, phone: cleanPhone(entry.phone), lastName: lastName(entry.name), district, street}
    })
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style >
  .mass-private-personal-text {
    padding: 10px 0;
  }
  h3 {
    padding: 0;
    margin: 0;
  }
</style>
