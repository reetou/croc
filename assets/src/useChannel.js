import { useState, useContext, useEffect } from 'react'
import { PhoenixSocketContext } from './SocketContext'

const useChannel = (channelName, onReply) => {
  const [channel, setChannel] = useState(null);
  const { socket } = useContext(PhoenixSocketContext);

  useEffect(() => {
    const phoenixChannel = socket.channel(channelName);
    phoenixChannel.join().receive('ok', (c) => {
      setChannel(phoenixChannel)
      if (onReply) {
        onReply(c, socket)
      }
    });

    // leave the channel when the component unmounts
    return () => {
      console.log('Left channel')
      phoenixChannel.leave();
    };
  }, []);
  // only connect to the channel once on component mount
  // by passing the empty array as a second arg to useEffect

  return [channel];
};

export default useChannel;
