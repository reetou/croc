import React, { createContext, useEffect, useState } from 'react'
import { Socket } from 'phoenix'
import socketClient from '../js/socket'

const PhoenixSocketContext = createContext({ socket: socketClient })

const PhoenixSocketProvider = ({ children }) => {
  const [socket, setSocket] = useState()

  useEffect(() => {
    setSocket(socketClient)
  }, [])

  if (!socket) return null

  return (
    <PhoenixSocketContext.Provider value={{ socket }}>
      {children}
    </PhoenixSocketContext.Provider>
  )
}

export { PhoenixSocketContext, PhoenixSocketProvider };
