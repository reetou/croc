import React, { useEffect, useState, lazy, Suspense } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Button,
  FixedLayout,
  Panel,
  PanelHeader,
  Placeholder,
  ScreenSpinner,
  Spinner,
  HeaderButton,
  View,
} from '@vkontakte/vkui'
import Game28Icon from '@vkontakte/icons/dist/28/game'
import { Stage } from '@inlet/react-pixi'
import Field from '../../game/monopoly/Field'
import { set } from 'lodash-es'
import PlayerSprite from '../../game/monopoly/PlayerSprite'
import { getMobileHeight, getMobileWidth } from '../../../util'
import useChannel from '../../../useChannel'
import { toJS } from 'mobx'
import ReactViewport from '../../ReactViewport'
import * as PIXI from 'pixi.js'

const VkActionContainer = lazy(() => import('../VkActionContainer'))
const Chat = lazy(() => import('../Chat'))


if (process.env.NODE_ENV !== 'production') {
  window.__PIXI_INSPECTOR_GLOBAL_HOOK__ &&
  window.__PIXI_INSPECTOR_GLOBAL_HOOK__.register({ PIXI: PIXI });
}

const mockFieldSettings = [
  {
    "position": 0,
    "form": "square",
    "point": {
      "x": 24.375,
      "y": 25.2109375
    }
  },
  {
    "position": 1,
    "form": "vertical",
    "point": {
      "x": 64.04296875,
      "y": 25.05859375
    }
  },
  {
    "position": 2,
    "form": "vertical",
    "point": {
      "x": 95.17578125,
      "y": 25.30078125
    }
  },
  {
    "position": 3,
    "form": "vertical",
    "point": {
      "x": 125.39453125,
      "y": 24.66015625
    }
  },
  {
    "position": 4,
    "form": "vertical",
    "point": {
      "x": 156.97265625,
      "y": 24.70703125
    }
  },
  {
    "position": 5,
    "form": "vertical",
    "point": {
      "x": 187.7421875,
      "y": 24.97265625
    }
  },
  {
    "position": 6,
    "form": "vertical",
    "point": {
      "x": 218.23828125,
      "y": 24.97265625
    }
  },
  {
    "position": 7,
    "form": "vertical",
    "point": {
      "x": 251.7890625,
      "y": 26.03515625
    }
  },
  {
    "position": 8,
    "form": "vertical",
    "point": {
      "x": 286.07421875,
      "y": 24.5390625
    }
  },
  {
    "position": 9,
    "form": "vertical",
    "point": {
      "x": 318.2421875,
      "y": 24.953125
    }
  },
  {
    "position": 10,
    "form": "square",
    "point": {
      "x": 354.10546875,
      "y": 23.73046875
    }
  },
  {
    "position": 11,
    "form": "horizontal",
    "point": {
      "x": 329.8125,
      "y": 67.4765625
    }
  },
  {
    "position": 12,
    "form": "horizontal",
    "point": {
      "x": 332.80859375,
      "y": 102.078125
    }
  },
  {
    "position": 13,
    "form": "horizontal",
    "point": {
      "x": 332.16015625,
      "y": 136.51953125
    }
  },
  {
    "position": 14,
    "form": "horizontal",
    "point": {
      "x": 327.51171875,
      "y": 172.36328125
    }
  },
  {
    "position": 15,
    "form": "horizontal",
    "point": {
      "x": 331.00390625,
      "y": 209.28125
    }
  },
  {
    "position": 16,
    "form": "horizontal",
    "point": {
      "x": 331.92578125,
      "y": 255.92578125
    }
  },
  {
    "position": 17,
    "form": "horizontal",
    "point": {
      "x": 332.578125,
      "y": 292.1875
    }
  },
  {
    "position": 18,
    "form": "horizontal",
    "point": {
      "x": 329.73828125,
      "y": 325.95703125
    }
  },
  {
    "position": 19,
    "form": "horizontal",
    "point": {
      "x": 328.0703125,
      "y": 361.390625
    }
  },
  {
    "position": 20,
    "form": "square",
    "point": {
      "x": 350.08984375,
      "y": 405.0703125
    }
  },
  {
    "position": 21,
    "form": "vertical",
    "point": {
      "x": 310.859375,
      "y": 405.94140625
    }
  },
  {
    "position": 22,
    "form": "vertical",
    "point": {
      "x": 279.328125,
      "y": 406.03125
    }
  },
  {
    "position": 23,
    "form": "vertical",
    "point": {
      "x": 248.44921875,
      "y": 403.7578125
    }
  },
  {
    "position": 24,
    "form": "vertical",
    "point": {
      "x": 219.859375,
      "y": 404.48046875
    }
  },
  {
    "position": 25,
    "form": "vertical",
    "point": {
      "x": 190.58203125,
      "y": 404.15234375
    }
  },
  {
    "position": 26,
    "form": "vertical",
    "point": {
      "x": 159.421875,
      "y": 403.6875
    }
  },
  {
    "position": 27,
    "form": "vertical",
    "point": {
      "x": 126.99609375,
      "y": 404.71484375
    }
  },
  {
    "position": 28,
    "form": "vertical",
    "point": {
      "x": 95.11328125,
      "y": 404.60546875
    }
  },
  {
    "position": 29,
    "form": "vertical",
    "point": {
      "x": 62.37890625,
      "y": 405.3671875
    }
  },
  {
    "position": 30,
    "form": "square",
    "point": {
      "x": 24.765625,
      "y": 406.0234375
    }
  },
  {
    "position": 31,
    "form": "horizontal",
    "point": {
      "x": 47.984375,
      "y": 361.87109375
    }
  },
  {
    "position": 32,
    "form": "horizontal",
    "point": {
      "x": 47.921875,
      "y": 326.0625
    }
  },
  {
    "position": 33,
    "form": "horizontal",
    "point": {
      "x": 49.21484375,
      "y": 290.60546875
    }
  },
  {
    "position": 34,
    "form": "horizontal",
    "point": {
      "x": 46.73046875,
      "y": 254.046875
    }
  },
  {
    "position": 35,
    "form": "horizontal",
    "point": {
      "x": 46.89453125,
      "y": 219.375
    }
  },
  {
    "position": 36,
    "form": "horizontal",
    "point": {
      "x": 46.3046875,
      "y": 182.61328125
    }
  },
  {
    "position": 37,
    "form": "horizontal",
    "point": {
      "x": 47.44921875,
      "y": 146.28125
    }
  },
  {
    "position": 38,
    "form": "horizontal",
    "point": {
      "x": 46.71875,
      "y": 108.6796875
    }
  },
  {
    "position": 39,
    "form": "horizontal",
    "point": {
      "x": 46.21875,
      "y": 71.21875
    }
  }
]

const getStageHeight = () => {
  return window.innerHeight - 170
}

function GameView(props) {
  // const enabled = process.env.NODE_ENV !== 'production'
  const enabled = false
  const [active, setActive] = useState(null)
  const [old, setOld] = useState(0)
  const state = useLocalStore((source) => ({
    activePanel: source.game ? 'game' : source.activePanel || 'no_game',
    fieldsInteractive: true,
    game: source.game,
    fieldSettings: mockFieldSettings,
    stageWidth: window.innerWidth,
    app: null,
    stageHeight: getStageHeight(),
    popout: <ScreenSpinner />
  }), props)
  useEffect(() => {
    if (props.game) {
      state.game = props.game
      state.activePanel = 'game'
    } else {
      state.activePanel = 'no_game'
      state.popout = null
      return
    }
    state.popout = null
    console.log('All set')
    const settings = props.game.cards
    // const settings = state.fieldSettings
      .map((c, i) => {
        const multiplier = parseInt((c.position) / 10)
        let columnIndex = i - (multiplier * 10)
        const isReversed = [1, 3].includes(multiplier)
        const isVertical = [0, 2].includes(multiplier)
        if (isReversed) {
          columnIndex = columnIndex * -1 + 9
        }
        const squareColumnIndexes = [0, 9]
        const squarePositions = [0, 10, 20, 30]
        const horizontalOrVertical = isVertical ? 'vertical' : 'horizontal'
        const form = squareColumnIndexes.includes(columnIndex) ? 'square' : 'horizontal'
        // const form = squarePositions.includes(c.position) ? 'square' : horizontalOrVertical
        const itemHeight = getMobileHeight(form)
        const itemWidth = getMobileWidth(form, state.stageWidth)
        const x = (multiplier * itemWidth) + itemWidth / 2
        let y = state.stageHeight - itemHeight / 2 - (itemHeight * columnIndex)
        // if (form === 'square') {
        //   y = 0
        // }
        // console.log(`Item height ${itemHeight}, item width: ${itemWidth} for position ${c.position}: multiplier: ${multiplier}, columnIndex: ${columnIndex}, regularIndex: ${i}`)
        // console.log(`stageHeight: ${state.stageHeight}, width: ${state.stageWidth}. Y for ${c.position}: ${y}, x: ${x}`)
        return {
          ...c,
          position: c.position,
          form,
          point: {
            x,
            y,
          }
        }
      })
    state.fieldSettings = settings
  }, [])
  const onJoin = (payload, socket) => {
    console.log('Joined USER CHANNEL WITH PAYLOAD', payload)
    // console.log('Successfully joined game channel', payload)
  }
  const channelName = `game:monopoly:${props.game ? props.game.game_id : 'noop'}`
  const userChannelName = `user:${props.user.id}`
  const [gameChannel] = useChannel(channelName, (payload) => {
    state.game = payload.game
    console.log('On game view join', payload)
  })
  const [userChannel] = useChannel(userChannelName, onJoin)
  useEffect(() => {
    if (!gameChannel) {
      console.log('No game channel, returning')
      return
    }
    //the LOAD_SCREENSHOT_MESSAGE is a message defined by the server
    gameChannel.on('game_update', payload => {
      console.log('Payload at game update', payload)
      state.game = payload.game
    })

    gameChannel.on('game_end', payload => {
      console.log('Game ENDED, setting shit')
      state.game = payload.game
      props.onGameEnd(payload.game)
    })
    //the LOAD_SCREENSHOT_MESSAGE is a message defined by the server
    gameChannel.on('error', payload => {
      console.log('GAME ERROR at vk game view', payload)
      setTimeout(() => {
        props.setActiveModal('lobby_error', payload.reason)
      }, 0)
    })

    gameChannel.on('event', payload => {
      console.log('Event happened', payload.event)
    })

    gameChannel.on('message', payload => {
      console.log('Message happened', payload)
      props.onShowSnackbar(payload.text)
      props.onChatMessage(payload)
    })

    // stop listening to this message before the component unmounts
    return () => {
      gameChannel.off(channelName, gameChannel)
    }
  }, [gameChannel])
  const disableFieldInteraction = () => {
    state.fieldsInteractive = false
  }
  const enableFieldInteraction = () => {
    state.fieldsInteractive = true
  }
  useEffect(() => {
    if (!userChannel) return
    userChannel.on('message', payload => {
      console.log('Payload at chat messaage', payload)
      props.onChatMessage(payload)
    })
    return () => {
      userChannel.off(userChannelName, userChannel)
    }
  }, [userChannel])
  return useObserver(() => (
    <View id={props.id} activePanel={state.activePanel}>
      <Panel id="no_game">
        <Placeholder
          icon={<Game28Icon />}
          title="Вы пока не в игре"
          action={(
            <Button
              onClick={() => props.onChangeStory('find_game')}
              size="xl"
            >
              Найти игру
            </Button>
          )}
        >
          Найдите игру и переходите сюда
        </Placeholder>
      </Panel>
      <Panel id={'game'}>
        <PanelHeader
          left={<HeaderButton onClick={() => state.activePanel = 'chat'}>{'Чат'}</HeaderButton>}
        >
          Игра
        </PanelHeader>
        <FixedLayout vertical="top">
          <Suspense fallback={<Spinner size="large"/>}>
            <VkActionContainer
              {...props}
              game={state.game}
              gameChannel={gameChannel}
            />
          </Suspense>
        </FixedLayout>
        <FixedLayout vertical="bottom">
          <Stage
            onMount={(a) => {
              state.app = a
            }}
            options={{
              backgroundColor: 0x10bb99,
              height: state.stageHeight,
              width: state.stageWidth
            }}
          >
            {
              state.fieldSettings && state.fieldSettings.length && state.app
                ? (
                  <ReactViewport
                    app={state.app}
                    disableFieldInteraction={disableFieldInteraction}
                    enableFieldInteraction={enableFieldInteraction}
                  >
                    {
                      state.game.cards.map(c => {
                        const playerOwner = c.owner ? state.game.players.find(p => p.player_id === c.owner) : null
                        const color = playerOwner ? playerOwner.color : false
                        return (
                          <Field
                            stageWidth={state.stageWidth}
                            mobile={true}
                            color={color}
                            enabled={enabled}
                            interactive={state.fieldsInteractive}
                            card={c}
                            key={c.id}
                            form={state.fieldSettings && state.fieldSettings[c.position] ? state.fieldSettings[c.position].form : 'horizontal'}
                            click={() => {
                              if (!enabled) {
                                props.setActiveOptionsModal('field_actions', {
                                  title: `Поле ${c.name}`,
                                  isOwner: c.owner && props.user.id === c.owner,
                                  card: c,
                                })
                              } else {
                                setOld(active)
                                setActive(c.position)
                              }
                            }}
                            x={state.fieldSettings[c.position].point.x}
                            y={state.fieldSettings[c.position].point.y}
                            onSubmitPoint={(v) => {
                              set(state, `fieldSettings.${c.position}.point.x`, v[0])
                              set(state, `fieldSettings.${c.position}.point.y`, v[1])
                              window.FIELDS_POSITIONS = toJS(state.fieldSettings)
                            }}
                          />
                        )
                      })
                    }
                    {
                      state.game.players.map(p => (
                        <PlayerSprite
                          image="https://s3-us-west-2.amazonaws.com/s.cdpn.io/693612/coin.png"
                          key={p.player_id}
                          squares={(
                            state.game.cards
                              .filter(c => {
                                if (!state.fieldSettings[c.position]) return false
                                return state.fieldSettings[c.position].form === 'square'
                              })
                              .map(c => {
                                const point = state.fieldSettings[c.position].point
                                return {
                                  ...c,
                                  point
                                }
                              })
                          )}
                          player_id={p.player_id}
                          color={p.color}
                          position={p.position}
                          old_position={p.old_position}
                          enabled={enabled}
                          x={state.fieldSettings[p.position].point.x}
                          y={state.fieldSettings[p.position].point.y}
                        />
                      ))
                    }
                  </ReactViewport>
                )
                : null
            }
          </Stage>
        </FixedLayout>
      </Panel>
      <Panel id={'chat'}>
        <Suspense fallback={<ScreenSpinner size="large" />}>
          <Chat
            onGoBack={() => {
              state.activePanel = 'game'
            }}
            messages={props.messages}
            sendMessage={(to, text) => {
              gameChannel.push('chat_message', {
                text,
                to,
                chat_id: state.game.chat_id
              })
            }}
          />
        </Suspense>
      </Panel>
    </View>
  ))
}

export default GameView
