import React, { createContext, useEffect, useState } from 'react'
import { Socket } from 'phoenix'
import socketClient from '../js/socket'

const PhoenixSocketContext = createContext({
  socket: socketClient,
  token: null,
})

const PhoenixSocketProvider = ({ children, userToken, wsUrl }) => {
  const [socket, setSocket] = useState(null)

  useEffect(() => {
    setSocket(socketClient)
  }, [])

  if (!socket) return null

  return (
    <PhoenixSocketContext.Provider value={{ socket, token: userToken }}>
      {children}
    </PhoenixSocketContext.Provider>
  )
}

export { PhoenixSocketContext, PhoenixSocketProvider };
