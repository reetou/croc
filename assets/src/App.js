import React from 'react'
import { PhoenixSocketProvider } from './SocketContext'
import LobbyContainer from "./components/lobby/LobbyContainer"

const Root = (props) => {
  return (
    <PhoenixSocketProvider wsUrl="localhost:4000/socket" options={{ token: window.userToken }}>
      <LobbyContainer {...props}/>
    </PhoenixSocketProvider>
  )
}

export default Root
