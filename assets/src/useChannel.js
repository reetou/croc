import { useState, useContext, useEffect } from 'react'
import { PhoenixSocketContext } from './SocketContext'

const useChannel = (channelName, onReply) => {
  const [channel, setChannel] = useState(null);
  const { socket, token } = useContext(PhoenixSocketContext)

  const setupChannel = () => {
    const phoenixChannel = token ? socket.channel(channelName, { token }) : socket.channel(channelName)
    console.log(`Joining with token ${token} to ${channelName}`)
    phoenixChannel
      .join()
      .receive('ok', (c) => {
        console.log('Joined successfully, cb is', c)
        setChannel(phoenixChannel)
        if (onReply) {
          onReply(c, socket)
        }
      })
      .receive('error', c => {
        console.error('Cannot connect: ', c)
      })
    return phoenixChannel
  }

  useEffect(() => {
    const phoenixChannel = setupChannel()
    // leave the channel when the component unmounts
    return () => {
      console.log('Left channel')
      phoenixChannel.leave();
    };
  }, [])
  // only connect to the channel once on component mount
  // by passing the empty array as a second arg to useEffect

  return [channel];
};

export default useChannel;
