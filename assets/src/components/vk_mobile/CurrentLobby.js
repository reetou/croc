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
  HorizontalScroll,
} from '@vkontakte/vkui'
import Icon24Back from '@vkontakte/icons/dist/24/back';
import { toJS } from 'mobx'
import axios from '../../axios'
import { flatten } from 'lodash-es'
import connect from '@vkontakte/vk-connect'
import VkEventCardThumb from './VkEventCardThumb'

function CurrentLobby(props) {
  if (!props.lobby) return null
  const state = useLocalStore((source) => ({
    lobby: source.lobby,
    loading: false,
    popout: null,
    get player() {
      return this.lobby.players.find((p => p.player_id === props.user.id))
    },
    get allEventCards() {
      return flatten(this.lobby.players.map(p => p.event_cards || []))
    },
    get lobbyUrl() {
      if (!state.lobby) return 'https://vk.com/app7262387'
      return `https://vk.com/app7262387#lobby_${state.lobby.lobby_id}`
    }
  }), props)
  useEffect(() => {
    state.lobby = props.lobby
  }, [props.lobby])
  const firstPlayer = state.lobby.players.find((p, i) => p.player_id && i === 0)
  const isOwner = firstPlayer.player_id === props.user.id
  const shareLobby = async () => {
    try {
      await connect.sendPromise("VKWebAppShare", {
        link: state.lobbyUrl
      })
    } catch (e) {
      console.error('Cannot share lobby', e)
    }
  }
  const createWallPost = async () => {
    try {
      await connect.send("VKWebAppShowWallPostBox", {
        message: 'Го в монополию\n' + state.lobbyUrl,
        attachments: `${state.lobbyUrl}`
      });
    } catch (e) {
      console.error('Cannot create wall post', e)
    }
  }
  const changeEventCards = () => {
    props.setActiveOptionsModal('edit_event_cards', {
      ...props.user,
      selected_event_cards: state.player.event_cards,
      onSubmit: async (selectedCardsIds) => {
        try {
          await axios({
            method: 'POST',
            url: '/lobby/set-event-cards',
            headers: {
              Authorization: `Bearer ${props.user.access_token}`
            },
            data: {
              lobby_id: props.lobby.lobby_id,
              event_cards_ids: selectedCardsIds,
            }
          })
        } catch (e) {
          console.log('Error at update deck', e)
          // Модалки не умеют открываться пока закрываются другие,
          // поэтому ждем пока промисы зарезолвятся
          setTimeout(() => {
            props.setActiveModal('lobby_error', 'Не получилось')
          }, 0)
        }
      }
    })
  }
  return useObserver(() => (
    <Panel id={props.id}>
      <PanelHeader
        left={<HeaderButton disabled={props.loading} onClick={props.onGoBack}><Icon24Back/></HeaderButton>}
      >
        Ваше лобби
      </PanelHeader>
      <Group>
        <List>
          {
            state.lobby.players
              .slice()
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
                    {p.name}
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
            onClick={changeEventCards}
          >
            Изменить колоду
          </Button>
        </Div>
        {
          isOwner
            ? (
              <Div>
                <Button
                  stretched
                  size={'l'}
                  disabled={props.loading}
                  mode={'primary'}
                  onClick={() => {
                    props.onTriggerLoading(true)
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
            disabled={props.loading}
            mode={'destructive'}
            onClick={() => {
              props.onTriggerLoading(true)
              props.leaveLobby(props.lobby.lobby_id)
            }}
          >
            Покинуть лобби
          </Button>
        </Div>
      </Group>
      {
        state.allEventCards && state.allEventCards.length
          ? (
            <Group header="Колода игры">
              <HorizontalScroll>
                <div style={{ display: 'flex' }}>
                  {
                    state.allEventCards.map(({ monopoly_event_card: c, id }) => (
                      <VkEventCardThumb
                        key={id}
                        src={c.image_url}
                      />
                    ))
                  }
                </div>
              </HorizontalScroll>
              <Footer>Колода игры состоит из всех колод всех игроков вашего лобби. Карты колоды расходуются после старта игры.</Footer>
            </Group>
          )
          : null
      }
      <Group description="Дайте своим друзьям отсканировать этот QR код или поделитесь ссылкой, чтобы друзья зашли к вам">
        <Div>
          <Button
            size="l"
            stretched
            mode="primary"
            onClick={shareLobby}
          >
            Поделиться ссылкой
          </Button>
        </Div>
        <Div>
          <Button
            size="l"
            stretched
            mode="outline"
            onClick={createWallPost}
          >
            Написать на стене
          </Button>
        </Div>
        <Div style={{ display: 'flex', justifyContent: 'center' }}>
          <div dangerouslySetInnerHTML={{ __html: props.qr }} />
        </Div>
      </Group>
      <Footer>Игра начнется, когда создатель нажмет на кнопку "Начать игру"</Footer>
    </Panel>
  ))
}

export default CurrentLobby
