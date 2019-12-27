import React from 'react'
import {
  Tabbar,
  TabbarItem,
} from '@vkontakte/vkui'
import { useObserver } from 'mobx-react-lite'
import Game24Icon from '@vkontakte/icons/dist/24/game';
import Video24Icon from '@vkontakte/icons/dist/24/video'
import Users24Icon from '@vkontakte/icons/dist/24/users'
import User24Icon from '@vkontakte/icons/dist/24/user'

function AppTabbar(props) {
  const {
    activeStory,
    onChangeStory
  } = props
  return useObserver(() => (
    <Tabbar>
      <TabbarItem
        onClick={() => onChangeStory('profile')}
        selected={activeStory === 'profile'}
        data-story="profile"
        text={props.user ? 'Профиль' : 'Войти'}
      >
        <User24Icon />
      </TabbarItem>
      <TabbarItem
        onClick={() => onChangeStory('find_game')}
        selected={activeStory === 'find_game'}
        data-story="find_game"
        text="Найти игру"
      >
        <Users24Icon />
      </TabbarItem>
      <TabbarItem
        onClick={() => onChangeStory('current_game')}
        selected={activeStory === 'current_game'}
        data-story="current_game"
        text="Игра"
      >
        <Game24Icon />
      </TabbarItem>
    </Tabbar>
  ))
}

export default AppTabbar
