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
  ModalRoot,
  ModalCard,
} from '@vkontakte/vkui'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import AppTabbar from './components/vk_mobile/AppTabbar'
import '@vkontakte/vkui/dist/vkui.css';
import LobbyView from './components/vk_mobile/views/LobbyView'
import Game28Icon from '@vkontakte/icons/dist/28/game'
import User28Icon from '@vkontakte/icons/dist/28/user'
import User24Icon from '@vkontakte/icons/dist/24/user'
import ErrorOutline56Icon from '@vkontakte/icons/dist/56/error_outline'
import DenyOutline56Icon from '@vkontakte/icons/dist/56/do_not_disturb_outline'

function VkMiniApp(props) {
  console.log('props', props)
  const state = useLocalStore(() => ({
    history: [],
    activeStory: 'find_game',
    activeModal: null,
    game: null,
    user: null,
  }))
  useEffect(() => {
    connect.send('VKWebAppInit')

    const handler = (e) => {
      console.log('Received VK event', e)
      if (e.detail.type === 'VKWebAppGetUserInfoResult') {
        console.log('Getting user info', e)
      }
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
      console.log('received email data', data)
      if (!data.email) {
        state.activeModal = 'email_not_confirmed'
        return
      }
      const userData = await connect.sendPromise('VKWebAppGetUserInfo')
      console.log('User data', userData)
      return data
    } catch (error) {
      console.log('Cannot get email data', error)
      // Handling an error
      state.activeModal = 'cannot_get_email'
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
      <ModalRoot activeModal={state.activeModal}>
        <ModalCard
          id={'email_not_confirmed'}
          onClose={() => state.activeModal = null}
          icon={<ErrorOutline56Icon />}
          title="Email не подтвержден"
          caption="Подтвердите Email в настройках профиля Вконтакте и попробуйте снова"
          actions={[{
            title: 'Сейчас сделаю',
            type: 'primary',
            action: () => state.activeModal = null
          }]}
        />
        <ModalCard
          id={'cannot_get_email'}
          onClose={() => state.activeModal = null}
          icon={<DenyOutline56Icon />}
          title="Не удалось получить E-mail"
          caption="Без вашего Email мы не можем допустить вас к игре.
          Пожалуйста, разрешите доступ к Email, чтобы продолжить."
          actions={[{
            title: 'Ладно',
            type: 'primary',
            action: signIn
          }]}
        />
      </ModalRoot>
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
