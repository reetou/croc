import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import VkLobby from './VkLobby'
import {
  Group,
  CellButton,
  List,
  Cell,
  Button,
} from '@vkontakte/vkui'
import Add24Icon from '@vkontakte/icons/dist/24/add';
import User24Icon from '@vkontakte/icons/dist/24/user';
import { toJS } from 'mobx'

function VkLobbyContainer(props) {
  console.log('Props at lobby container', props)
  return useObserver(() => (
    <React.Fragment>
      <Cell>
        {
          props.user
            ? (
              <CellButton
                disabled={!props.user}
                onClick={props.onCreateLobby}
                before={<Add24Icon />}
              >
                Создать
              </CellButton>
            )
            : (
              <Button
                disabled={props.user}
                before={<User24Icon />}
                size="xl"
                onClick={props.signIn}
              >
                Войти
              </Button>
            )
        }
      </Cell>
      <Group title="Игры">
        <List>
          {
            props.lobbies.map(l => {
              console.log('Lobby', toJS(l))
              const member = l.players.find(p => p.player_id === props.user.id)
              const canJoin = !l.closed && !member
              const { players } = l
              const owner = players.length && props.user && players[0].player_id == props.user.id

              return (
                <VkLobby
                  key={l.lobby_id}
                  member={member}
                  onJoin={() => {
                    if (props.user) {
                      props.joinLobby(l.lobby_id)
                    } else {
                      props.signIn()
                    }
                  }}
                  canJoin={canJoin}
                  leaveLobby={() => {
                    props.leaveLobby(l.lobby_id)
                  }}
                  owner={owner}
                  lobby={l}
                  user={props.user}
                />
              )
            })
          }
        </List>
      </Group>
    </React.Fragment>
  ))
}

export default VkLobbyContainer
