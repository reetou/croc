import React, { useEffect, useState } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import useChannel from '../../../useChannel'
import { PhoenixSocketProvider } from '../../../SocketContext'
import MonopolyTable from './MonopolyTable'
import ActionContainer from './ActionContainer'
import styled from 'styled-components'

const EventsContainer = styled.div`
  display: flex;
  flex-direction: column;
  height: 300px;
  overflow-y: scroll;
`

const Row = styled.div`
  display: flex;
`

function Game(props) {
  if (!props.game) {
    throw new Error('No game in props')
  }
  const state = useLocalStore(() => ({
    game: props.game,
    game_events: [],
    card: null,
  }))
  const onJoin = (payload, socket) => {
    // console.log('Successfully joined game channel', payload)
  }
  const channelName = `game:monopoly:${props.game.game_id}`
  const [gameChannel] = useChannel(channelName, onJoin)
  // listening for messages from the channel
  useEffect(() => {
    if (!gameChannel) {
      console.log('No game channel, returning')
      return
    }
    //the LOAD_SCREENSHOT_MESSAGE is a message defined by the server
    gameChannel.on('game_update', payload => {
      console.log('Payload at game update', payload)
      state.game = payload.game
      state.card = null
    })
    //the LOAD_SCREENSHOT_MESSAGE is a message defined by the server
    gameChannel.on('error', payload => {
      console.log('GAME ERROR', payload)
      alert(payload.reason)
    })

    gameChannel.on('event', payload => {
      console.log('Event happened')
      state.game_events.push(payload.event)
    })

    // stop listening to this message before the component unmounts
    return () => {
      gameChannel.off(channelName, gameChannel)
    }
  }, [gameChannel])
  return useObserver(() => (
    <PhoenixSocketProvider>
      <Row>
        <div style={{ width: '50%' }}>
          {
            state.game.players.map((p) => {
              return (
                <div>
                  <p>Игрок {p.player_id}</p>
                  <p>Баланс: {p.balance}</p>
                  <p>{p.surrender ? 'Сдался' : 'Играет'}</p>
                </div>
              )
            })
          }
        </div>
        <EventsContainer>
          {
            state.game_events.map((e) => {
              return (
                <div>
                  <p>{e.amount}</p>
                  <p>{e.type}</p>
                  <p>{e.text}</p>
                </div>
              )
            })
          }
        </EventsContainer>
      </Row>
      <ActionContainer card={state.card} game={state.game} user={props.user} channel={gameChannel} />
      <MonopolyTable onCardClick={(card) => { state.card = card }} game={state.game} />
    </PhoenixSocketProvider>
  ))
}

export default Game
