<template>
  <div class="family">
    <div class="family-name">{{ name }}</div>
    <div v-html="formattedAddress"></div>
    <div>{{ phone }}</div>
    <div>{{ email }}</div>
    <ul>
      <li v-for="member in members">{{ member.name }}</li>
    </ul>
  </div>
</template>

<script>
export default {
  name: 'Family',
  props:['type'],
  sync:['name', 'address', 'phone', 'email', 'members'],
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
.family-name {
  font-weight: bold;
}
.contact-info {
  padding-left: 2em;
}
</style>

