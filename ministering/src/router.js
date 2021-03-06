import Vue from 'vue'
import Router from 'vue-router'
import Home from './views/Home.vue'
import Ministering from './views/Ministering.vue'
import Sisters from './views/Sisters.vue'
import Reports from './views/Reports.vue'
import Yearbook from '@/components/Yearbook.vue'
import Directory from '@/components/Directory.vue'
import MinisteringConcerns from '@/components/MinisteringConcerns.vue'
import MassPrivatePersonalText from '@/components/MassPrivatePersonalText.vue'
import TextList from '@/components/TextList.vue'
import EmailList from '@/components/EmailList.vue'

Vue.use(Router)

export default new Router({
  mode: 'history',
  base: process.env.BASE_URL,
  routes: [
    {
      path: '/ministering-concerns',
      name: 'MinisteringConcerns',
      component: MinisteringConcerns
    },
    {
      path: '/',
      name: 'Ministering',
      component: Ministering
    },
    {
      path: '/directory',
      name: 'Directory',
      component: Directory
    },
    {
      path: '/text',
      name: 'MassPrivatePersonalText',
      component: MassPrivatePersonalText
    },
    {
      path: '/sisters',
      name: 'Sisters',
      component: Sisters
    },
    {
      path: '/reports',
      name: 'Reports',
      component: Reports
    },
    {
      path: '/yearbook',
      name: 'Yearbook',
      component: Yearbook
    },
    {
      path: '/textlist',
      name: 'TextList',
      component: TextList
    },
    {
      path: '/emaillist',
      name: 'EmailList',
      component: EmailList
    },
    {
      path: '/about',
      name: 'about',
      // route level code-splitting
      // this generates a separate chunk (about.[hash].js) for this route
      // which is lazy-loaded when the route is visited.
      component: () => import(/* webpackChunkName: "about" */ './views/About.vue')
    }
  ]
})
