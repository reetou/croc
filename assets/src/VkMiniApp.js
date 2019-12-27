import React, { useEffect } from 'react'
import { PhoenixSocketProvider } from './SocketContext'
import LobbyContainer from "./components/lobby/LobbyContainer"
import connect from '@vkontakte/vk-connect'

function VkMiniApp(props) {
  useEffect(() => {
    connect.send('VKWebAppInit')

    const handler = (e) => {
      console.log('Received VK event', e)
    }

    connect.subscribe(handler)

    return () => {
      console.log('Unsubscribing')
      connect.unsubscribe(handler)
    }
  }, [])
  const sendLogin = async () => {
    try {
      console.log('Send login')
      const data = await connect.sendPromise('VKWebAppGetEmail')

      // Handling received data
      console.log('received email data', data);
    } catch (error) {
      console.log('Cannot get email data', error)
      // Handling an error
    }
  }
  return (
    <PhoenixSocketProvider wsUrl="localhost:4000/socket" options={{ token: window.userToken }}>
      <LobbyContainer {...props}/>
      <button onClick={sendLogin}>Войти</button>
    </PhoenixSocketProvider>
  )
}

export default VkMiniApp
