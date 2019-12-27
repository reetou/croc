// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css"

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
import socket from "./socket"
import "react-phoenix"
import LobbyContainer from '../src/components/lobby/LobbyContainer'
import VkMiniApp from '../src/VkMiniApp'
import Game from '../src/components/game/monopoly/Game'

window.Components = {
  LobbyContainer,
  Game,
  VkMiniApp,
}
