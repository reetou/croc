import React, { useEffect, useState, lazy, Suspense } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Button,
  FixedLayout,
  Panel,
  Placeholder,
  ScreenSpinner,
  Spinner,
  View,
} from '@vkontakte/vkui'
import Game28Icon from '@vkontakte/icons/dist/28/game'
import { Stage } from '@inlet/react-pixi'
import Field from '../../game/monopoly/Field'
import { set } from 'lodash-es'
import PlayerSprite from '../../game/monopoly/PlayerSprite'
import * as PIXI from 'pixi.js'
import { getMobileHeight, getMobileWidth } from '../../../util'
import useChannel from '../../../useChannel'

const VkActionContainer = lazy(() => import('../VkActionContainer'))


if (process.env.NODE_ENV !== 'production') {
  window.__PIXI_INSPECTOR_GLOBAL_HOOK__ &&
  window.__PIXI_INSPECTOR_GLOBAL_HOOK__.register({ PIXI: PIXI });
}

const mockFieldSettings = [
  {
    "form": "horizontal",
    "point": {
      "x": 49.79296875,
      "y": 582.46875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 51.1484375,
      "y": 539.97265625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 52.3046875,
      "y": 498.75
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 52.97265625,
      "y": 457.515625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 53.53125,
      "y": 417.2578125
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 52.90625,
      "y": 376.48046875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 53.62109375,
      "y": 336.5703125
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 53.69140625,
      "y": 295.7109375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 54.2578125,
      "y": 254.421875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 56.41796875,
      "y": 212.99609375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 58.0703125,
      "y": 171.07421875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 58.70703125,
      "y": 129.9765625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 58.37109375,
      "y": 86.65625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 152.40625,
      "y": 84.3671875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 247.359375,
      "y": 83.6015625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 341.609375,
      "y": 85.7734375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 340.4921875,
      "y": 127.8046875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 340.484375,
      "y": 170.78515625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 341.390625,
      "y": 213.68359375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 336.15625,
      "y": 254.98046875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 334.65234375,
      "y": 295.71875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 334.46484375,
      "y": 333.38671875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 333.078125,
      "y": 372.3984375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 332.4296875,
      "y": 410.45703125
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 334.3515625,
      "y": 452.8671875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 330.21875,
      "y": 492.6640625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 329.08984375,
      "y": 533.68359375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 328.25,
      "y": 574.2734375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 233.921875,
      "y": 570.15234375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 234.640625,
      "y": 528.828125
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 235.234375,
      "y": 490.375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 234.93359375,
      "y": 451.33984375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 235.6875,
      "y": 409.02734375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 238.3359375,
      "y": 366.6484375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 143.95703125,
      "y": 377.2734375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 146.921875,
      "y": 418.6640625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 147.265625,
      "y": 459.0390625
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 146.58984375,
      "y": 496.9921875
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 145.375,
      "y": 540.5859375
    }
  },
  {
    "form": "horizontal",
    "point": {
      "x": 147.0390625,
      "y": 580.21875
    }
  }
]

const getStageHeight = () => {
  const itemHeight = getMobileHeight('horizontal')
  const height = window.innerHeight
  const tabbarHeight = 52
  if (height <= itemHeight * 10 + 100) {
    return height
  }
  return itemHeight * 10
}

function GameView(props) {
  // const enabled = process.env.NODE_ENV !== 'production'
  const enabled = false
  const [active, setActive] = useState(null)
  const [old, setOld] = useState(0)
  const state = useLocalStore(() => ({
    activePanel: props.activePanel || 'no_game',
    game: props.game,
    fieldSettings: [],
    messages: [],
    stageWidth: window.innerWidth,
    stageHeight: getStageHeight(),
    popout: <ScreenSpinner />
  }))
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
      .map((c, i) => {
        const multiplier = parseInt((c.position) / 10)
        let columnIndex = i - (multiplier * 10)
        const isReversed = [1, 3].includes(multiplier)
        if (isReversed) {
          columnIndex = columnIndex * -1 + 9
        }
        const squareColumnIndexes = [0, 9]
        const form = squareColumnIndexes.includes(columnIndex) ? 'square' : 'horizontal'
        const itemHeight = getMobileHeight(form)
        const itemWidth = getMobileWidth(form, state.stageWidth)
        const x = (multiplier * itemWidth) + itemWidth / 2
        let y = state.stageHeight - itemHeight / 2 - (itemHeight * columnIndex)
        return {
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
    })

    gameChannel.on('event', payload => {
      console.log('Event happened', payload.event)
    })

    gameChannel.on('message', payload => {
      console.log('Message happened', payload)
      props.onShowSnackbar(payload.text)
      state.messages.push(payload)
    })

    // stop listening to this message before the component unmounts
    return () => {
      gameChannel.off(channelName, gameChannel)
    }
  }, [gameChannel])
  return useObserver(() => (
    <View id={props.id} activePanel={state.activePanel} header={false}>
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
          <Stage options={{ backgroundColor: 0x10bb99, height: state.stageHeight, width: state.stageWidth }}>
            {
              state.fieldSettings && state.fieldSettings.length
                ? (
                  <React.Fragment>
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
                            card={c}
                            key={c.id}
                            form={state.fieldSettings[c.position].form}
                            click={() => {
                              props.setActiveOptionsModal('field_actions', {
                                title: `Поле ${c.name}`,
                                isOwner: c.owner && props.user.id === c.owner,
                                card: c,
                              })
                              if (!enabled) return
                              setOld(active)
                              setActive(c.position)
                            }}
                            x={state.fieldSettings[c.position].point.x}
                            y={state.fieldSettings[c.position].point.y}
                            onSubmitPoint={(v) => {
                              set(state, `fieldSettings.${c.position}.point.x`, v[0])
                              set(state, `fieldSettings.${c.position}.point.y`, v[1])
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
                  </React.Fragment>
                )
                : null
            }
          </Stage>
        </FixedLayout>
      </Panel>
    </View>
  ))
}

export default GameView
