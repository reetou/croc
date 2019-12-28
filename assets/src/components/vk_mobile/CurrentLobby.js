import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Panel,
  PanelHeader,
  HeaderButton,
  Group,
  List,
  Cell,
  Avatar,
  Footer,
  Div,
  Button,
  InfoRow,
} from '@vkontakte/vkui'
import Icon24Back from '@vkontakte/icons/dist/24/back';

function CurrentLobby(props) {
  if (!props.lobby) return null
  const state = useLocalStore(() => ({
    loading: false
  }))
  const firstPlayer = props.lobby.players.find((p, i) => p.player_id && i === 0)
  const isOwner = firstPlayer.player_id === props.user.id
  return useObserver(() => (
    <Panel id={props.id}>
      <PanelHeader
        left={<HeaderButton disabled={state.loading} onClick={props.onGoBack}><Icon24Back/></HeaderButton>}
      >
        Ваше лобби
      </PanelHeader>
      <Group>
        <InfoRow>
          {props.lobby.lobby_id}
        </InfoRow>
        <List>
          {
            props.lobby.players
              .sort((a, b) => {
                const owner = a.player_id === firstPlayer.player_id
                if (owner) {
                  return 9999
                }
                return a.player_id
              })
              .map((p, i) => {
                const owner = i === 0
                return (
                  <Cell
                    key={p.player_id}
                    before={<Avatar src={p.image_url} />}
                    description={owner ? 'Создатель' : 'Игрок'}
                  >
                    {p.player_id}
                  </Cell>
                )
              })
          }
        </List>
        <Div>
          <Button
            stretched
            size={'l'}
            mode={'secondary'}
            onClick={() => {
              props.setActiveModal('edit_event_cards')
            }}
            disabled
          >
            Изменить колоду (В разработке)
          </Button>
        </Div>
        {
          isOwner
            ? (
              <Div>
                <Button
                  stretched
                  size={'l'}
                  disabled={state.loading}
                  mode={'primary'}
                  onClick={() => {
                    state.loading = true
                    props.startGame(props.lobby.lobby_id)
                  }}
                >
                  Начать игру
                </Button>
              </Div>
            )
            : null
        }
        <Div>
          <Button
            stretched
            size={'l'}
            disabled={state.loading}
            mode={'destructive'}
            onClick={() => {
              state.loading = true
              props.leaveLobby(props.lobby.lobby_id)
            }}
          >
            Покинуть лобби
          </Button>
        </Div>
      </Group>
      <Footer>Игра начнется, когда создатель нажмет на кнопку "Начать игру"</Footer>
    </Panel>
  ))
}

export default CurrentLobby
