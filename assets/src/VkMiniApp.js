import React, { useEffect } from 'react'
import { PhoenixSocketProvider } from './SocketContext'
import LobbyContainer from "./components/lobby/LobbyContainer"
import connect from '@vkontakte/vk-connect'

function VkMiniApp(props) {
  useEffect(() => {
    connect.send('VKWebAppInit')

    connect.subscribe(e => {
      console.log('Received VK event', e)
    })
  }, [])
  return (
    <PhoenixSocketProvider wsUrl="localhost:4000/socket" options={{ token: window.userToken }}>
      <LobbyContainer {...props}/>
    </PhoenixSocketProvider>
  )
}

export default VkMiniApp
