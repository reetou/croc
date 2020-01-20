import React, { useEffect, useContext } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import { HeaderButton, Panel, PanelHeader, ScreenSpinner, View } from '@vkontakte/vkui'
import VkLobbyContainer from '../VkLobbyContainer'
import Icon24Qr from '@vkontakte/icons/dist/24/qr'
import useChannel from '../../../useChannel'
import CurrentLobby from '../CurrentLobby'
import connect from '@vkontakte/vk-connect'
import { PhoenixSocketContext } from '../../../SocketContext'
import vkQr from '@vkontakte/vk-qr'


function LobbyView(props) {
  const state = useLocalStore(() => ({
    activePanel: 'main',
    game_id: null,
    lobbies: [],
    errors: [],
    popout: null,
    lobby_qr: null,
    loading: false,
    joined_lobby_id: null,
    get lobby() {
      if (!this.joined_lobby_id) return null
      return this.lobbies.find(l => l.lobby_id === this.joined_lobby_id)
    },
    joinedLobbyChannel: null,
    newLobby(payload) {
      console.log('new lobby', payload)
      this.lobbies = [...this.lobbies, payload]
    },
    lobbyError(payload) {
      console.log('Error at lobby', payload)
      this.errors = [...this.errors, payload]
      if (props.setActiveModal) {
        props.setActiveModal('lobby_error', payload.reason)
        if (state.popout) {
          state.popout = null
        }
        state.loading = false
      }
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
  const { token } = useContext(PhoenixSocketContext)
  const onJoin = (payload, socket) => {
    const { lobby_id, lobbies } = payload
    if (lobbies) {
      console.log('Setting lobbies to state')
      state.lobbies = lobbies
    }
    if (!lobby_id) {
      console.log('No lobby_id')
      return
    }
    console.log('Received joined', payload)
    if (state.joinedLobbyChannel) {
      state.joinedLobbyChannel.leave()
    }
    const topic = `lobby:${lobby_id}`
    console.log('Topic')
    const chan = socket.channel(topic, { token })
    state.joined_lobby_id = lobby_id
    const maxQrSize = 300
    const qrSvg = vkQr.createQR(`https://vk.com/app7262387#lobby_${lobby_id}`, {
      qrSize: window.innerWidth - 80 > maxQrSize ? maxQrSize : window.innerWidth - 80,
      isShowLogo: true,
      foregroundColor: props.darkTheme ? '#F5F5F5' : '#000000'
    })
    state.lobby_qr = qrSvg
    chan.on('game_start', (payload) => {
      console.log('Game is gonna start!!!!', payload)
      state.game_id = payload.game.game_id
      props.onGameStart(payload.game)
      state.loading = false
    })
    chan.on('left', (payload) => {
      if (payload.force) {
        props.setActiveModal('lobby_error', payload.reason)
      }
      onLeave(payload)
    })
    chan.join()
      .receive('ok', () => {
        console.log(`Joined LOBBY topic ${topic}`)
      })
      .receive('error', (e) => {
        console.log(`Cannot connect lobby topic ${topic}`, e)
      })
    state.joinedLobbyChannel = chan
    state.activePanel = 'in_lobby'
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
    state.loading = false
  }
  const joinLobby = (lobby_id) => {
    lobbyChannel.push('join', {
      lobby_id,
    })
  }
  const scanLobbyCode = async () => {
    try {
      const data = await connect.send("VKWebAppOpenCodeReader", {})
      if (data.code_data && data.code_data.includes('lobby_')) {
        const lobby_id = data.code_data.split('lobby_')[1]
        if (lobby_id === state.joined_lobby_id) {
          return
        }
        joinLobby(lobby_id)
      }
    } catch (e) {
      console.error('Cannot scan lobby code', e)
    }
  }
  const startGame = (lobby_id) => {
    lobbyChannel.push('start', {
      lobby_id,
    })
    state.popout = <ScreenSpinner />
  }
  const onLeave = (payload) => {
    console.log('Received left', payload)
    if (!state.joined_lobby_id !== payload.lobby_id)
    if (state.joinedLobbyChannel) {
      state.joinedLobbyChannel.leave()
      state.joinedLobbyChannel = null
    }
    state.activePanel = 'main'
    state.joined_lobby_id = null
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
    if (window.location.hash.startsWith('#lobby_')) {
      const lobby_id = window.location.hash.split('lobby_')[1]
      connect.send("VKWebAppSetLocation", { location: '' })
      joinLobby(lobby_id)
    }

    // stop listening to this message before the component unmounts
    return () => {
      lobbyChannel.off('lobby:all', lobbyChannel)
      if (state.joinedLobbyChannel) {
        state.joinedLobbyChannel.leave()
      }
    }
  }, [lobbyChannel])
  return useObserver(() => (
    <View activePanel={state.activePanel} popout={state.popout}>
      <Panel id="main">
        <PanelHeader
          left={
            props.platform !== 'desktop_web'
              ? (
                <HeaderButton
                  disabled={state.loading}
                  onClick={scanLobbyCode}
                >
                  <Icon24Qr />
                </HeaderButton>
              )
              : null
          }
        >
          Найти игру
        </PanelHeader>
        <VkLobbyContainer
          onGoToLobby={(lobby) => {
            state.joined_lobby_id = lobby.lobby_id
            state.activePanel = 'in_lobby'
          }}
          user={props.user}
          onCreateLobby={createLobby}
          lobbies={state.lobbies}
          signIn={props.signIn}
          joinLobby={joinLobby}
          leaveLobby={leaveLobby}
        />
      </Panel>
      <CurrentLobby
        {...props}
        onGoBack={() => { state.activePanel = 'main' }}
        id="in_lobby"
        lobby={state.lobby}
        qr={state.lobby_qr}
        leaveLobby={leaveLobby}
        loading={state.loading}
        onTriggerLoading={(prop) => {
          state.loading = prop
        }}
        startGame={startGame}
      />
    </View>
  ))
}

export default LobbyView
