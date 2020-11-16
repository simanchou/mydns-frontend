import Vue from 'vue'
import SvgIcon from '@/components/SvgIcon'// svg component

// register globally
Vue.component('svg-icon', SvgIcon)

const req = require.context('./svg', false, /\.svg$/)
const avatar_fruit = require.context('./svg/avatar/fruit', false, /\.svg$/)
const requireAll = requireContext => requireContext.keys().map(requireContext)
requireAll(req)
requireAll(avatar_fruit)
