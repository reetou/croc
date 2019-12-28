import React, { useEffect } from 'react'
import { PhoenixSocketProvider } from './SocketContext'
import connect from '@vkontakte/vk-connect'
import {
  PanelHeader,
  View,
  Panel,
  Epic,
  Placeholder,
  Button,
} from '@vkontakte/vkui'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import AppTabbar from './components/vk_mobile/AppTabbar'
import '@vkontakte/vkui/dist/vkui.css';
import LobbyView from './components/vk_mobile/views/LobbyView'
import Game28Icon from '@vkontakte/icons/dist/28/game'
import User28Icon from '@vkontakte/icons/dist/28/user'
import User24Icon from '@vkontakte/icons/dist/24/user'
import axios from './axios'
import Modals from './components/vk_mobile/Modals'

function VkMiniApp(props) {
  console.log('props', props)
  const state = useLocalStore(() => ({
    history: [],
    activeStory: 'find_game',
    activeModal: null,
    game: null,
    token: null,
    user: null,
  }))
  useEffect(() => {
    const handler = (e) => {
      console.log('Received VK event', e)
    }
    connect.subscribe(handler)
    connect.send('VKWebAppInit')
    getUserData()
    return () => {
      console.log('Unsubscribing')
      connect.unsubscribe(handler)
    }
  }, [])
  const getUserData = async () => {
    try {
      if (process.env.NODE_ENV !== 'production') {
        state.token = 'SFMyNTY.g3QAAAACZAAEZGF0YWEUZAAGc2lnbmVkbgYAwavJSW8B.35xr0ff0rqzV5gNKuFZ8MEv70WLYH5SnyGXb2gXdkp0'
      }
      const userData = await connect.sendPromise('VKWebAppGetUserInfo')
      console.log('User data', userData)
      const res = await axios.post('/vk/auth', userData)
      state.user = res.data.user
      state.token = res.data.token
    } catch (e) {
      console.log('User error', e)
      state.activeModal = 'cannot_get_user_data'
    }
  }
  const getEmail = async () => {
    try {
      const data = await connect.sendPromise('VKWebAppGetEmail')
      // Handling received data
      console.log('received email data', data)
      if (!data.email) {
        state.activeModal = 'email_not_confirmed'
        return
      }
    } catch (e) {
      console.log('Cannot get email data', error)
      // Handling an error
      state.activeModal = 'cannot_get_email'
    }
  }
  const signIn = async () => {
    await getUserData()
  }
  const onChangeStory = (story) => {
    state.activeStory = story
  }
  const onGameStart = (game) => {
    state.activeStory = 'current_game'
    state.game = game
  }
  useEffect(() => {
    console.log('Token ADDED', state.token)
  }, [state.token])
  const wsUrl = process.env.NODE_ENV !== 'production' ? 'ws://localhost:4000/socket' : 'wss://crocapp.gigalixir.com/socket'
  return useObserver(() => (
    <PhoenixSocketProvider wsUrl={wsUrl} userToken={state.token}>
      <Modals
        onClose={() => { state.activeModal = null }}
        onSignIn={signIn}
        onGetUserData={getUserData}
      />
      <Epic
        activeStory={state.activeStory}
        tabbar={<AppTabbar activeStory={state.activeStory} onChangeStory={onChangeStory} />}
      >
        <View id={'profile'} activePanel={'main'}>
          <Panel id={'main'}>
            <PanelHeader>Профиль</PanelHeader>
            {
              state.user
                ? (
                  <div>User</div>
                )
                : (
                  <Placeholder
                    icon={<User28Icon />}
                    title="Вы еще не вошли в Монополию"
                    action={
                      (
                        <Button
                          size="xl"
                          onClick={signIn}
                          before={<User24Icon />}
                        >
                          Войти
                        </Button>
                      )
                    }
                  >
                    После входа вы сможете играть в игру, зарабатывать баллы и многое другое
                  </Placeholder>
                )
            }
          </Panel>
        </View>
        <LobbyView
          {...props}
          signIn={signIn}
          user={state.user}
          id={'find_game'}
          onGameStart={onGameStart}
        />
        <View id={'current_game'} activePanel="main" header={false}>
          <Panel id="main">
            <Placeholder
              icon={<Game28Icon />}
              title="Вы пока не в игре"
              action={<Button size="xl">Найти игру</Button>}
            >
              Найдите игру и переходите сюда
            </Placeholder>
          </Panel>
        </View>
        <View id="games" activePanel="main">
          <Panel id="main">
            <PanelHeader>Смотреть игры</PanelHeader>
          </Panel>
        </View>
      </Epic>
    </PhoenixSocketProvider>
  ))
}

export default VkMiniApp
