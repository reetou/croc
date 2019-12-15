import React, { useState, useEffect, useContext } from 'react'
import useChannel from "../../useChannel"
import { useLocalStore, useObserver } from 'mobx-react-lite'

function LobbyContainer(props) {
  console.log('Props', props)
  const state = useLocalStore(() => ({
    game_id: null,
    lobbies: props.lobbies || [],
    errors: [],
    lobby: null,
    joinedLobbyChannel: null,
    newLobby(payload) {
      console.log('new lobby', payload)
      this.lobbies = [...this.lobbies, payload]
    },
    lobbyError(payload) {
      console.log('Error', payload)
      this.errors = [...this.errors, payload]
    },
    lobbyUpdate(payload) {
      if (payload.players.length === 0) {
        return
      }
      this.lobbies = this.lobbies.map((l) => {
        if (l.lobby_id === payload.lobby_id) {
          return payload
        }
        return l
      })
    }
  }))
  const onJoin = (payload, socket) => {
    const { lobby_id } = payload
    if (!lobby_id) {
      console.log('No lobby_id')
      return
    }
    console.log('Received joined', payload)
    if (state.joinedLobbyChannel) {
      state.joinedLobbyChannel.leave()
    }
    const topic = `lobby:${lobby_id}`
    const chan = socket.channel(topic)
    state.lobby = lobby_id
    chan.on('game_start', (payload) => {
      console.log('Game is gonna start', payload)
      state.game_id = payload.game.game_id
      window.location.href = `${props.game_path}${state.game_id}`
    })
    chan.join().receive('ok', () => {
      console.log(`Joined topic ${topic}`)
    })
    state.joinedLobbyChannel = chan
  }
  const onLeave = (payload) => {
    console.log('Received left', payload)
    if (state.joinedLobbyChannel) {
      state.joinedLobbyChannel.leave()
      state.joinedLobbyChannel = null
    }
  }
  const [lobbyChannel] = useChannel('lobby:all', onJoin)
  const inLobby = (lobby) => {
    return lobby.players.some(p => p.player_id === props.user.id)
  }
  const createLobby = () => {
    lobbyChannel.push('create', {
      name: 'Только собаки',
      options: [],
    })
  }
  const leaveLobby = (lobby_id) => {
    lobbyChannel.push('leave', {
      lobby_id,
    })
    if (state.joinedLobbyChannel) {
      state.joinedLobbyChannel.leave()
    }
  }
  const joinLobby = (lobby_id) => {
    lobbyChannel.push('join', {
      lobby_id,
    })
  }
  const startGame = (lobby_id) => {
    lobbyChannel.push('start', {
      lobby_id,
    })
  }

  // listening for messages from the channel
  useEffect(() => {
    if (!lobbyChannel) {
      console.log('No lobby channel, returning')
      return
    }
    console.log('Setting up listeners')

    //the LOAD_SCREENSHOT_MESSAGE is a message defined by the server
    lobbyChannel.on('new_lobby', state.newLobby)
    lobbyChannel.on('error', state.lobbyError)
    lobbyChannel.on('lobby_update', (payload) => {
      console.log('Lobby updated', payload)
      state.lobbyUpdate(payload)
    })
    lobbyChannel.on('lobby_destroy', (payload) => {
      console.log('Lobby destroyed', payload)
      state.lobbies = state.lobbies.filter((l) => l.lobby_id !== payload.lobby_id)
    })
    lobbyChannel.on('joined', (payload) => {
      onJoin(payload, lobbyChannel.socket)
    })
    lobbyChannel.on('left', (payload) => {
      onLeave(payload)
    })

    // stop listening to this message before the component unmounts
    return () => {
      lobbyChannel.off('lobby:all', lobbyChannel)
      if (state.joinedLobbyChannel) {
        state.joinedLobbyChannel.leave()
      }
    }
  }, [lobbyChannel])
  return useObserver(() => (
    <React.Fragment>
      {
        state.game_id
          ? (
            <div>
              <h1>
                Your game has started. <a href={`${props.game_path}${state.game_id}`}>Go to game</a>
              </h1>
            </div>
          )
          : null
      }
      {
        state.errors.map((e) => (
          <div>Ошибка: {e.reason}</div>
        ))
      }
      <div>
        Confirmed at {state.lobby}
      </div>
      <button onClick={createLobby}>Create</button>
      {
        state.lobbies.length === 0
          ? (
            <h1>No lobbies. Create one</h1>
          )
          : null
      }
      {
        state.lobbies.map(l => {
          const member = inLobby(l)
          const canJoin = !l.closed && !member
          const { players } = l
          const owner = players.length && players[0].player_id == props.user.id

          return (
            <div key={l.lobby_id}>
              Lobby id: {l.lobby_id}
              <div style={{ display: 'flex', flexDirection: 'column' }}>
                {
                  l.players.map((p, i) => {
                    const lobbyOwner = !i
                    return (
                      <p>{lobbyOwner ? '[Owner]' : ''} Player {p.player_id}</p>
                    )
                  })
                }
                { member ? <button onClick={() => leaveLobby(l.lobby_id)}>Leave</button> : null }
                { canJoin ? <button onClick={() => joinLobby(l.lobby_id)}>Join</button> : null }
                { owner ? <button onClick={() => startGame(l.lobby_id)}>Start</button> : null }
              </div>
            </div>
          )
        })
      }
    </React.Fragment>
  ))
}

// export default observer(LobbyContainer)
export default LobbyContainer
