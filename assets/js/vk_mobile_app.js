// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative paths, for example:
import "react-phoenix"
import VkMiniApp from '../src/VkMiniApp'
import connect from '@vkontakte/vk-connect'

console.log('Sending init yo')
connect.send('VKWebAppInit', {})
  .then((r) => {
    console.log('Init result', r)
  })
  .catch(e => {
    console.error('Cannot init', e)
  })

window.Components = {
  VkMiniApp,
}
