<template>
  <div class="ministering">

    <div class="district" v-if="yearbook" v-for="district in ministeringAssignments">
    <p style="font-style: italic; margin-bottom: 1em;">Note: only districts starting with 'district' will be displayed.</p>
    <District  
      :companionships.sync="district.companionships" 
      :districtName.sync="district.districtName" 
      :supervisor.sync="district.supervisor" 
      inline-template>

      <div>
        <h2 class="district-name">{{ districtName }}</h2>

        <div class="companionship" v-for="companionship in companionships">

        <div class="supervisor">
        <Minister 
          type="supervisor"
          :name.sync="supervisor.name" 
          :address.sync="supervisor.address" 
          :phone.sync="supervisor.phone" 
          :email.sync="supervisor.email" 
          :yearbook="$parent.yearbook"
          >
        </Minister>
        </div>
        
        <Companionship 
          :assignments.sync="companionship.assignments" 
          :ministers.sync="companionship.ministers" 
          inline-template>
          <div class="columns">
            <div class="ministers column">
            <div class="minister" v-for="minister in ministers">
            <Minister
              type="minister"
              :name.sync="minister.name" 
              :address.sync="minister.address" 
              :phone.sync="minister.phone" 
              :email.sync="minister.email" 
              :yearbook="$parent.$parent.yearbook"
              >
            </Minister>
            </div>
            </div>
          
            <div class="assignments column">
            <div class="assignment" v-for="assignment in assignments">
            <Family
              :name.sync="assignment.name" 
              :address.sync="assignment.address" 
              :phone.sync="assignment.phone" 
              :email.sync="assignment.email" 
              :members.sync="assignment.members" 
              >
            </Family>
            </div>
            </div>
          
          </div>
        </Companionship>
        </div>

      </div>
    </District>
    </div>
    
  </div>
</template>

<script>
import Vue from 'vue'
import ministeringAssignments from '../../../ministering-assignments-print-out.json'
import yearbook from '../../../yearbook.json'
import Minister from '@/components/Minister.vue'
import Family from '@/components/Family.vue'

Vue.component('District', {
	template: '#checkbox-template',
  components: { Minister, },
  sync:['companionships', 'districtName', 'supervisor'], //this is the special option added by the mixin
  data: function () {
    return {
    }
  },
  mounted() {
    // console.log(">>>$parent.yearbook", this.$parent.yearbook)
  },
})

Vue.component('Companionship', {
  components: { Minister, Family, },
  sync:['assignments', 'ministers'],
  data: function () {
    return {
    }
  },
})

Vue.component('Assignment', {
  sync:['name', 'address', 'phone', 'email'],
  data: function () {
    return {
    }
  },
})

export default {
  name: 'Ministering',
  props: {
    msg: String, 
  },
  methods: {
    ministerPhoto(minister) {
      return this.yearbook.find(entry => entry.name === minister.name)
    }
  },
  data: function() {
    return {
      ministeringAssignments: [],
      yearbook: [],
    }
  },
  mounted () {
    this.ministeringAssignments = ministeringAssignments.filter(entry => entry.districtName.startsWith('district'));
    this.yearbook = yearbook;
  },
}
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style>
.ministering {
  width: 100%;
}
.district {
  display: block;
  margin: 0 auto;
  clear: both;
  width: 100%;
}
.district-name {
  font-weight: bold;
  background-color: whitesmoke; 
  border-bottom: 1px solid silver;
}
.supervisor {
  display: block;
}
.companionship {
  display: block;
  border-bottom: 1px solid silver;
  padding-top: 1em;
  padding-bottom: 1em;
}
/* .columns { */
/*   margin-top: 1em; */
/*   width: 45%; */
/*   display: inline-block; */
/*   vertical-align: top; */
/* } */
.ministers {
}
.assignments {
}
.minister {
  display: block;
  padding-bottom: 1em;
}
.assignment {
  display: block;
  padding-bottom: 1em;
}
</style>
