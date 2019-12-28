import React, { useEffect, useContext } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import { Div, Panel, PanelHeader, View } from '@vkontakte/vkui'
import VkLobbyContainer from '../VkLobbyContainer'
import useChannel from '../../../useChannel'
import CurrentLobby from '../CurrentLobby'
import { PhoenixSocketContext } from '../../../SocketContext'


function LobbyView(props) {
  const state = useLocalStore(() => ({
    activePanel: 'main',
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
      if (this.lobby && this.lobby.lobby_id === payload.lobby_id) {
        this.lobby = payload
      }
    }
  }))
  const { token } = useContext(PhoenixSocketContext)
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
    const chan = socket.channel(topic, { token })
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
  const [lobbyChannel] = useChannel('lobby:all', onJoin)
  const inLobby = (lobby) => {
    if (!props.user) return false
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
  const onLeave = (payload) => {
    console.log('Received left', payload)
    if (state.joinedLobbyChannel) {
      state.joinedLobbyChannel.leave()
      state.joinedLobbyChannel = null
    }
  }
  // listening for messages from the channel
  useEffect(() => {
    if (!lobbyChannel) {
      console.log('No lobby channel at lobby view, returning')
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
    <View activePanel={state.activePanel}>
      <Panel id="main">
        <PanelHeader>Найти игру</PanelHeader>
        <VkLobbyContainer
          user={props.user}
          onCreateLobby={createLobby}
          lobbies={state.lobbies}
          signIn={props.signIn}
          joinLobby={joinLobby}
          leaveLobby={leaveLobby}
        />
      </Panel>
      <CurrentLobby
        id="in_lobby"
        lobby={state.lobby}
        leaveLobby={leaveLobby}
        startGame={startGame}
      />
    </View>
  ))
}

export default LobbyView
