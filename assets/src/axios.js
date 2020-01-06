const axios = require('axios')
const host = process.env.API_HOST || 'https://crocapp.gigalixirapp.com'
console.log(`Host at axios`, host)
const instance = axios.create({
  withCredentials: true,
  baseURL: process.env.NODE_ENV === 'production' ? host + '/api' : 'https://vk.eu.ngrok.io/api'
})

module.exports = instance
