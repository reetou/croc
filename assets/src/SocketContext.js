import React, { createContext, useEffect, useState } from 'react'
import { Socket } from 'phoenix'
import socketClient from '../js/socket'

const PhoenixSocketContext = createContext({
  socket: socketClient,
  token: null,
})

const PhoenixSocketProvider = ({ children, userToken, wsUrl }) => {
  const [socket, setSocket] = useState(null)
  const [token, setToken] = useState(window.userToken)

  useEffect(() => {
    setSocket(socketClient)
  }, [])

  useEffect(() => {
    setToken(userToken)
  }, [userToken])

  if (!socket) return null

  return (
    <PhoenixSocketContext.Provider value={{ socket, token }}>
      {children}
    </PhoenixSocketContext.Provider>
  )
}

export { PhoenixSocketContext, PhoenixSocketProvider };
