<template>
  <div class="ministering-concerns">
    <div>
      View: {{view}}; show <button @click="toggleView">{{(view == 'simple') ? 'table' : 'simple'}}</button>
    </div>

    <div>
      <input type="checkbox" id="include-ym" v-model="includeYm">
      <label for="include-ym"> Include YM?</label>
    </div>

    <div v-show="view == 'simple'" class="view-01">
      <Group :districts="districts" inline-template>
        <div>
          <h4>Brothers who need a companion</h4>
          <div v-for="district in districts" :key="district.id">
            <span class="district-leader-name">District leader: {{district.leader}}</span>
            <ul>
              <li class="brother" v-for="brother in district.brothers" :key="brother.id">
                <div class="name">{{brother.name_age}}</div><div class="street">{{brother.district_name}}</div>
              </li>
            </ul>
          </div>
        </div>
      </Group>

      <Group :districts="districts" inline-template>
        <div>
          <h4>Families who need ministering brothers</h4>
          <div v-for="district in districts" :key="district.id">
            <span class="district-leader-name">District leader: {{district.leader}}</span>
            <ul>
              <li class="family" v-for="family in district.families" :key="family.id">
                <div class="name">{{family.name}}</div><div class="street">{{family.district_name}}</div>
              </li>
            </ul>
          </div>
        </div>
      </Group>

    </div>

    <!-- === -->

    <div v-show="view == 'table'" class="view-02">
      <br>
      
      <Group :districts="districts" inline-template>
        <div>
          <h3>Brothers who need a companion</h3>
          <br>
          <table class="concerns" style="">
            <tr v-for="district in districts" :key="district.id">
              <td>
                <p><span class="district-leader">District leader:</span> {{district.leader}}</p>
                <table class="district-concerns">
                  <tr v-for="brother in district.brothers" :key="brother.id"> <td style="width: 400px;">{{brother.name_age}}</td> <td style="width: 150px;">{{brother.district_name}}</td> </tr>
                </table>
                <br>
                
              </td>
            </tr>
          </table>
        </div>
      </Group>

      <Group :districts="districts" inline-template>
        <div>
          <h3>Families who need ministering brothers</h3>
          <table class="concerns" style="">
            <tr v-for="district in districts" :key="district.id">
              <td>
                <p><span class="district-leader">District leader:</span> {{district.leader}}</p>
                <table class="district-concerns">
                  <tr v-for="family in district.families" :key="family.id"> <td style="width: 400px;">{{family.name}}</td> <td style="width: 150px;">{{family.district_name}}</td> </tr>
                </table>
                <br>
                
              </td>
            </tr>
          </table>
        </div>
      </Group>
    </div>
  </div>
</template>

<script>
import Vue from 'vue'
import report from '../../../report-summary.json'

const YM_MINISTERING_AGE_THRESHOLD = 18

String.prototype.hashCode = function() {
  var hash = 0, i, chr;
  if (this.length === 0) return hash;
  for (i = 0; i < this.length; i++) {
    chr   = this.charCodeAt(i);
    hash  = ((hash << 5) - hash) + chr;
    hash |= 0; // Convert to 32bit integer
  }
  return hash;
};

const getBrothers = (data, districtNumber, options) => {
  const { includeYm } = options
  const re = new RegExp(`^0${districtNumber}-`)
  var reAge = /\(([^\)]*)\)/

  return Object.keys(data.ministering_brothers)
  .filter(district_name => district_name.match(re))
  .reduce((list, district_name) => {

    let brothers = data.ministering_brothers[district_name]

    // if the option is turned off to include YM ministering companions in the
    // report for ministers without companions, do not include YM ministering
    // brothers
    if (!includeYm) brothers = brothers
      .filter(brother => {
        const md = brother.match(reAge)
        const brotherAge = Number.parseInt(md[1])
        return brotherAge >= YM_MINISTERING_AGE_THRESHOLD
      })

    brothers = brothers
    .map(name_age => ({id: name_age.hashCode(), name_age, district_name}))

    list = list.concat(brothers)
    return list

  }, [])
};

const getFamilies = (data, districtNumber) => {
  const re = new RegExp(`^0${districtNumber}-`)
  return Object.keys(data.ministering_families).filter(district_name => district_name.match(re)).reduce((list, district_name) => {
    const families = data.ministering_families[district_name].map(name => ({id: name.hashCode(), name, district_name}))
    list = list.concat(families)
    return list
  }, [])
};

Vue.component('Group', {
  props:['districts'],
})

export default {
  name: 'MinisteringConcerns',
  data() {
    return {
      report: {},
      view: "table", // simple, table
      includeYm: false,
    }
  },
  computed: {
    districts: function() {
      const { includeYm } = this
      let data = [
        {id: 1, leader: "Pres. Nitta", brothers: [], families: []},
        {id: 2, leader: "Bro. Fidler", brothers: [], families: []},
        {id: 3, leader: "Bro. Stilson", brothers: [], families: []},
      ]
      if (!this.report || !this.report.ministering_brothers) return data

      data[0].brothers = getBrothers(this.report, 1, { includeYm })
      data[1].brothers = getBrothers(this.report, 2, { includeYm })
      data[2].brothers = getBrothers(this.report, 3, { includeYm })

      data[0].families = getFamilies(this.report, 1)
      data[1].families = getFamilies(this.report, 2)
      data[2].families = getFamilies(this.report, 3)

      return data
    },
  },
  methods: {
    toggleView: function() {
      this.view = (this.view == 'simple') ? 'table' : 'simple'
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
  .ministering-concerns .family div,
  .ministering-concerns .brother div {
    display: inline-block;
  }
  .ministering-concerns .family .name,
  .ministering-concerns .brother .name {
    width: 300px;
  }
  .ministering-concerns .family .street,
  .ministering-concerns .brother .street {
    margin-left: 1em;
    width: 250px;
  }

  table.district-concerns {
    border-collapse: collapse;
  }
  table.district-concerns th td, 
  table.district-concerns tr td {
    /* border: 1px solid silver; */
    padding: 2px;
  }

  .concerns .district-leader {
    font-weight: bold;
    margin: 1em auto;
  }

  .ministering-concerns h3 {
    background: whitesmoke;
  }

  .ministering-concerns p {
    margin: 1em auto;
  }

  .ministering-concerns h3 {
    margin-top: 2em;
  }
  .minitering-concerns br { display: none; }
</style>
