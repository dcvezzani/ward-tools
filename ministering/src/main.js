import Vue from 'vue'
import App from './App.vue'
import router from './router'
import store from './store'

require('./assets/sass/main.scss')

Vue.config.productionTip = false

window.Event = new Vue()

Vue.mixin({
	beforeCreate(){
  	const sync = this.$options.sync
  	if(sync){
    	if(!this.$options.computed){
      	this.$options.computed = {}
      }
      const attrs = Object.keys(this.$attrs)
      sync.forEach(key => {
      	if(!attrs.includes(key)){
        	Vue.util.warn(`Missing required sync-prop: "${key}"`, this)
        }
        this.$options.computed[key] = {
        	get(){
          	return this.$attrs[key]
          },
          set(val){
          	this.$emit('update:' + key, val)
          }
        }
      })
    }
  }
})

new Vue({
  router,
  store,
  render: h => h(App)
}).$mount('#app')
