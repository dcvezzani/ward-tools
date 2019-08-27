<template>
  <div class="ministering-concerns">
  xxx
  </div>
</template>

<script>
import Vue from 'vue'
import report from '../../../report-summary.json'

export default {
  name: 'MinisteringConcerns',
  data() {
    return {
      report: {},
    }
  },
  mounted() {
    this.report = report
  },
  beforeDestroy() {
  },
}

</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style >
</style>
