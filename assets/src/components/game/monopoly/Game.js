import React, { useEffect, useState } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import useChannel from '../../../useChannel'
import { PhoenixSocketProvider } from '../../../SocketContext'
import DesktopActionContainer from './DesktopActionContainer'
import styled from 'styled-components'
import GameTable from './GameTable'

const EventsContainer = styled.div`
  display: flex;
  flex-direction: column;
  height: 250px;
  width: 50%;
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
    messages: [],
    card: null,
    get isWinner() {
      return this.game.winners.includes(props.user.id)
    },
    now: Date.now(),
    get timeLeft() {
      if (!this.game.turn_timeout_at) return -1
      const timeoutTime = new Date(this.game.turn_timeout_at).getTime()
      if (this.now > timeoutTime) return 0
      return parseInt((timeoutTime - this.now) / 1000, 10)
    }
  }))
  const onJoin = (payload, socket) => {
    console.log('Joined USER CHANNEL WITH PAYLOAD', payload)
    // console.log('Successfully joined game channel', payload)
  }
  const channelName = `game:monopoly:${props.game.game_id}`
  const userChannelName = `user:${props.user.id}`
  const [gameChannel] = useChannel(channelName)
  const [userChannel] = useChannel(userChannelName, onJoin)
  useEffect(() => {
    const interval = setInterval(() => {
      state.now = Date.now()
    }, 1000)
    return () => {
      clearInterval(interval)
    }
  }, [])
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

    gameChannel.on('game_end', payload => {
      document.title = 'Игра окончена'
      console.log('Game ENDED, setting shit')
      state.game = payload.game
      state.card = null
    })
    //the LOAD_SCREENSHOT_MESSAGE is a message defined by the server
    gameChannel.on('error', payload => {
      console.log('GAME ERROR', payload)
      alert(payload.reason)
    })

    gameChannel.on('event', payload => {
      console.log('Event happened', payload.event)
      state.game_events.push(payload.event)
    })

    gameChannel.on('message', payload => {
      console.log('Message happened', payload)
      state.messages.push(payload)
    })

    // stop listening to this message before the component unmounts
    return () => {
      gameChannel.off(channelName, gameChannel)
    }
  }, [gameChannel])
  useEffect(() => {
    if (!userChannel) {
      console.log('No USER game channel, returning')
      return
    }

    userChannel.on('message', payload => {
      console.log('Payload at chat message', payload)
      state.messages.push(payload)
    })

    // stop listening to this message before the component unmounts
    return () => {
      userChannel.off(userChannelName, userChannel)
    }
  }, [userChannel])
  return useObserver(() => (
    <PhoenixSocketProvider>
      <h1>Осталось на ход: {state.timeLeft} сек</h1>
      <Row>
        <div style={{ width: '50%' }}>
          {
            state.game.players.map((p) => {
              return (
                <div key={p.player_id}>
                  {
                    p.surrender
                      ? <s><p>Игрок {p.player_id} сдался</p></s>
                      : <p>Игрок {p.player_id}. Баланс: {p.balance}</p>
                  }
                </div>
              )
            })
          }
        </div>
        <EventsContainer>
          {
            state.messages.map((e) => {
              return (
                <div>
                  <p>From {e.from}</p>
                  <p>{e.type}</p>
                  <p>{e.text}</p>
                </div>
              )
            })
          }
        </EventsContainer>
      </Row>
      {
        state.isWinner
          ? (
            <h1>ВЫ ПОБЕДИЛИ</h1>
          )
          : (
            <React.Fragment>
              <DesktopActionContainer card={state.card} game={state.game} user={props.user} channel={gameChannel} />
              <GameTable game={state.game} />
            </React.Fragment>
          )
      }
    </PhoenixSocketProvider>
  ))
}

export default Game
