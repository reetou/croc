import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import useChannel from '../../useChannel'
import styled from 'styled-components'

const MessageContainer = styled.div`
  margin-top: 10px;
  display: flex;
  flex-direction: column;
  padding: 10px;
  border: 2px solid black;
`

function GameMessages(props) {
  const state = useLocalStore(() => ({
    messages: []
  }))
  console.log('Joining to topic', props.topic)
  const [messageChannel] = useChannel(props.topic)
  useEffect(() => {
    if (!messageChannel) {
      console.log('No message channel')
      return
    }
    messageChannel.on('messages', payload => {
      console.log('Received some messages to admin', payload)
      state.messages = state.messages.concat(payload.messages)
    })
    return () => {
      messageChannel.off(props.topic, messageChannel)
    }
  }, [messageChannel])
  return useObserver(() => (
    <div>
      {
        state.messages.map(m => {
          return (
            <MessageContainer>
              <div style={{ display: 'flex', justifyContent: 'space-between' }}>
                <div>
                  <span style={{ marginRight: 8 }}>Кому: {m.to ? `Игроку ${m.to}` : 'Всем'}</span>
                  <span>От: {m.from}</span>
                </div>
                <span>{m.sent_at}</span>
              </div>
              <p>{m.text}</p>
            </MessageContainer>
          )
        })
      }
    </div>
  ))
}

export default GameMessages
