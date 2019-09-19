<template>
  <div class="supervisor" v-if="type == 'supervisor'">
    Presidency Member: <span class="minister-name">{{ name }}</span> <span class="contact-info"> <span>{{ phone }}</span> | <span>{{ email }}</span> </span>
  </div>
  <div v-else="">
    <div class="minister-name">{{ name }}</div>
    <div v-html="formattedAddress"></div>
    <div>{{ phone }}</div>
    <div>{{ email }}</div>
  </div>
</template>

<script>
export default {
  name: 'Minister',
  props:['type'],
  sync:['name', 'address', 'phone', 'email'],
  computed: {
    formattedAddress: function () {
      return this.address.replace(/\n/, "<br/>")
    }
  },
  data: function () {
    return {
    }
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.minister-name {
  font-weight: bold;
}
.contact-info {
  padding-left: 2em;
}
.supervisor {
  margin: 0 0 1em 0;
  font-style: italic;
}
</style>

