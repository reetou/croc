import React, { useEffect } from 'react'
import { useAsObservableSource, useObserver } from 'mobx-react-lite'
import {
  Avatar,
  Button,
  Cell,
  Group,
  Panel,
  PanelHeader,
  Placeholder,
  View,
  List,
} from '@vkontakte/vkui'
import User28Icon from '@vkontakte/icons/dist/28/user'
import User24Icon from '@vkontakte/icons/dist/24/user'
import { toJS } from 'mobx'

function ProfileView(props) {
  const state = useAsObservableSource(props)
  useEffect(() => {
    props.getUserData()
  }, [])
  console.log('User', toJS(state.user))
  return useObserver(() => (
    <View id={props.id} activePanel={state.activePanel}>
      <Panel id={'banned'}>
        <PanelHeader>Бан</PanelHeader>
        <Placeholder
          icon={<User28Icon />}
          header={`Номер бана: ${state.ban_id}`}
        >
          Вы были заблокированы. Для разбана напишите номер бана и ваше сообщение сюда: vk.com/zaeeee (ЧЕТЫРЕ буквы е)
        </Placeholder>
      </Panel>
      <Panel id={'main'}>
        <PanelHeader>Профиль</PanelHeader>
        {
          state.user
            ? (
              <React.Fragment>
                <Group>
                  <Cell
                    photo={state.user.image_url}
                    description="Игрок"
                    before={<Avatar src={state.user.image_url} size={80}/>}
                    size="l"
                  >
                    {state.user.first_name} {state.user.last_name}
                  </Cell>
                </Group>
                <Group header="Колода">
                  <List>
                    {
                      state.user.user_monopoly_event_cards.map(({ id, monopoly_event_card: c }) => (
                        <Cell
                          key={id}
                          description={c.description}
                          before={<Avatar src={state.user.image_url} size={36}/>}
                          size="l"
                        >
                          {c.name}
                        </Cell>
                      ))
                    }
                  </List>
                </Group>
              </React.Fragment>
            )
            : (
              <Placeholder
                icon={<User28Icon />}
                title="Вы еще не вошли в Монополию"
                action={
                  (
                    <Button
                      size="xl"
                      onClick={state.signIn}
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
  ))
}

export default ProfileView
