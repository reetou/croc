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

function VkMiniApp(props) {
  console.log('props', props)
  const state = useLocalStore(() => ({
    activeStory: 'find_game',
    game: null,
    user: null,
  }))
  useEffect(() => {
    connect.send('VKWebAppInit')

    const handler = (e) => {
      console.log('Received VK event', e)
    }

    connect.subscribe(handler)

    return () => {
      console.log('Unsubscribing')
      connect.unsubscribe(handler)
    }
  }, [])
  const signIn = async () => {
    try {
      console.log('Send login')
      const data = await connect.sendPromise('VKWebAppGetEmail')

      // Handling received data
      console.log('received email data', data);
    } catch (error) {
      console.log('Cannot get email data', error)
      // Handling an error
    }
  }
  const onChangeStory = (story) => {
    state.activeStory = story
  }
  const onGameStart = (game) => {
    state.activeStory = 'current_game'
    state.game = game
  }
  const wsUrl = process.env.NODE_ENV !== 'production' ? 'localhost:4000/socket' : 'crocapp.gigalixir.com/socket'
  return useObserver(() => (
    <PhoenixSocketProvider wsUrl={wsUrl} options={{ token: window.userToken }}>
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
