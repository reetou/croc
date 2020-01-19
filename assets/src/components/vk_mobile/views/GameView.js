import React, {
  useEffect,
  useState,
  lazy,
  Suspense,
} from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Button,
  Panel,
  PanelHeader,
  Placeholder,
  ScreenSpinner,
  HeaderButton,
  View,
} from '@vkontakte/vkui'
import Game28Icon from '@vkontakte/icons/dist/28/game'
import { Container, Graphics, Sprite, Stage, Text } from '@inlet/react-pixi'
import Field from '../../game/monopoly/Field'
import { set } from 'lodash-es'
import PlayerSprite from '../../game/monopoly/PlayerSprite'
import { getPosition } from '../../../util'
import useChannel from '../../../useChannel'
import { toJS } from 'mobx'
import ReactViewport from '../../ReactViewport'
import * as PIXI from 'pixi.js'
import VkActionContainer from '../VkActionContainer'
import Deck from '../../game/monopoly/Deck'
import colorString from 'color-string'
// import Paper from 'paper'

const Chat = lazy(() => import('../Chat'))


PIXI.settings.RESOLUTION = window.devicePixelRatio || 1

if (process.env.NODE_ENV !== 'production') {
  window.__PIXI_INSPECTOR_GLOBAL_HOOK__ &&
  window.__PIXI_INSPECTOR_GLOBAL_HOOK__.register({ PIXI: PIXI });
}

const mockFieldSettings = [
  {
    "position": 0,
    "form": "square",
    "point": {
      "x": 28,
      "y": 29
    }
  },
  {
    "position": 1,
    "form": "vertical",
    "point": {
      "x": 148 - 21,
      "y": 145
    }
  },
  {
    "position": 2,
    "form": "vertical",
    "point": {
      "x": 207 - 21,
      "y": 145
    }
  },
  {
    "position": 3,
    "form": "vertical",
    "point": {
      "x": 266 - 21,
      "y": 145
    }
  },
  {
    "position": 4,
    "form": "vertical",
    "point": {
      "x": 325 - 21,
      "y": 145
    }
  },
  {
    "position": 5,
    "form": "vertical",
    "point": {
      "x": 384 - 21,
      "y": 145
    }
  },
  {
    "position": 6,
    "form": "vertical",
    "point": {
      "x": 443 - 21,
      "y": 145
    }
  },
  {
    "position": 7,
    "form": "vertical",
    "point": {
      "x": 502 - 21,
      "y": 145
    }
  },
  {
    "position": 8,
    "form": "vertical",
    "point": {
      "x": 561 - 21,
      "y": 145
    }
  },
  {
    "position": 9,
    "form": "vertical",
    "point": {
      "x": 620 - 21,
      "y": 145
    }
  },
  {
    "position": 10,
    "form": "vertical",
    "point": {
      "x": 679 - 21,
      "y": 145
    }
  },
  {
    "position": 11,
    "form": "vertical",
    "point": {
      "x": 738 - 21,
      "y": 145
    }
  },
  {
    "position": 12,
    "form": "vertical",
    "point": {
      "x": 797 - 21,
      "y": 145
    }
  },
  {
    "position": 13,
    "form": "square",
    "point": {
      "x": 856,
      "y": 29
    }
  },
  {
    "position": 14,
    "form": "horizontal",
    "point": {
      "x": 856,
      "y": 149
    }
  },
  {
    "position": 15,
    "form": "horizontal",
    "point": {
      "x": 856,
      "y": 208
    }
  },
  {
    "position": 16,
    "form": "horizontal",
    "point": {
      "x": 856,
      "y": 267
    }
  },
  {
    "position": 17,
    "form": "horizontal",
    "point": {
      "x": 856,
      "y": 326
    }
  },
  {
    "position": 18,
    "form": "horizontal",
    "point": {
      "x": 856,
      "y": 385
    }
  },
  {
    "position": 19,
    "form": "horizontal",
    "point": {
      "x": 856,
      "y": 444
    }
  },
  {
    "position": 20,
    "form": "horizontal",
    "point": {
      "x": 856,
      "y": 503
    }
  },
  {
    "position": 21,
    "form": "horizontal",
    "point": {
      "x": 856,
      "y": 562
    }
  },
  {
    "position": 22,
    "form": "square",
    "point": {
      "x": 856,
      "y": 621
    }
  },
  {
    "position": 23,
    "form": "vertical-flip",
    "point": {
      "x": 797,
      "y": 621 + 116
    }
  },
  {
    "position": 24,
    "form": "vertical-flip",
    "point": {
      "x": 738,
      "y": 621 + 116
    }
  },
  {
    "position": 25,
    "form": "vertical-flip",
    "point": {
      "x": 679,
      "y": 621 + 116
    }
  },
  {
    "position": 26,
    "form": "vertical-flip",
    "point": {
      "x": 620,
      "y": 621 + 116
    }
  },
  {
    "position": 27,
    "form": "vertical-flip",
    "point": {
      "x": 560,
      "y": 621 + 116
    }
  },
  {
    "position": 28,
    "form": "vertical-flip",
    "point": {
      "x": 502,
      "y": 621 + 116
    }
  },
  {
    "position": 29,
    "form": "vertical-flip",
    "point": {
      "x": 443,
      "y": 621 + 116
    }
  },
  {
    "position": 30,
    "form": "vertical-flip",
    "point": {
      "x": 384,
      "y": 621 + 116
    }
  },
  {
    "position": 31,
    "form": "vertical-flip",
    "point": {
      "x": 325,
      "y": 621 + 116
    }
  },
  {
    "position": 32,
    "form": "vertical-flip",
    "point": {
      "x": 266,
      "y": 621 + 116
    }
  },
  {
    "position": 33,
    "form": "vertical-flip",
    "point": {
      "x": 207,
      "y": 621 + 116
    }
  },
  {
    "position": 34,
    "form": "vertical-flip",
    "point": {
      "x": 148,
      "y": 621 + 116
    }
  },
  {
    "position": 35,
    "form": "square",
    "point": {
      "x": 28,
      "y": 621
    }
  },
  {
    "position": 36,
    "form": "horizontal-flip",
    "point": {
      "x": 7,
      "y": 562
    }
  },
  {
    "position": 37,
    "form": "horizontal-flip",
    "point": {
      "x": 7,
      "y": 503
    }
  },
  {
    "position": 38,
    "form": "horizontal-flip",
    "point": {
      "x": 7,
      "y": 444
    }
  },
  {
    "position": 39,
    "form": "horizontal-flip",
    "point": {
      "x": 7,
      "y": 385
    }
  },
  {
    "position": 40,
    "form": "horizontal-flip",
    "point": {
      "x": 7,
      "y": 326
    }
  },
  {
    "position": 41,
    "form": "horizontal-flip",
    "point": {
      "x": 7,
      "y": 267
    }
  },
  {
    "position": 42,
    "form": "horizontal-flip",
    "point": {
      "x": 7,
      "y": 208
    }
  },
  {
    "position": 43,
    "form": "horizontal-flip",
    "point": {
      "x": 7,
      "y": 149
    }
  }
]

function GameView(props) {
  // const enabled = process.env.NODE_ENV !== 'production'
  const actionContainerRef = React.createRef()
  const enabled = false
  const [active, setActive] = useState(null)
  const [old, setOld] = useState(0)
  const state = useLocalStore((source) => ({
    activePanel: source.game ? 'game' : source.activePanel || 'no_game',
    fieldsInteractive: true,
    game: source.game,
    following: false,
    fieldSettings: mockFieldSettings,
    popout: <ScreenSpinner />,
    stageWidth: window.innerWidth / PIXI.settings.RESOLUTION,
    app: null,
    stageHeight: window.innerHeight / PIXI.settings.RESOLUTION,
    stageReady: false,
    segments: [],
    painting: false,
    path: null,
    get now() {
      return Date.now()
    },
    get timeLeft() {
      if (!this.game.turn_timeout_at) return -1
      const timeoutTime = new Date(this.game.turn_timeout_at).getTime()
      if (this.now > timeoutTime) return 0
      return parseInt((timeoutTime - this.now) / 1000, 10)
    },
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
    state.fieldSettings = mockFieldSettings
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
  const configureGameWindowSize = (cw, ch) => {
    const gamePanel = 'game'
    if (state.activePanel !== gamePanel) {
      return
    }
    const elem = document.getElementById(gamePanel)
    const tabbarHeight = 50
    const height = ch ? ch - tabbarHeight : window.innerHeight - tabbarHeight
    const width = cw || window.innerWidth
    state.stageWidth = width / PIXI.settings.RESOLUTION
    state.stageHeight = height / PIXI.settings.RESOLUTION
    console.log(`Configured size ${state.stageWidth}x${state.stageHeight}`)
  }
  useEffect(() => {
    configureGameWindowSize()
  }, [])
  useEffect(() => {
    state.stageReady = true
    state.app.resize()
  }, [state.stageHeight])
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
      props.onShowSnackbar(payload)
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
  const paintRef = React.useRef(null)
  // useEffect(() => {
  //   const canvas = paintRef.current
  //   Paper.setup(canvas)
  //   const onDrawStart = (e) => {
  //     console.log('Clicked on canvas', e)
  //     state.painting = true
  //     state.path = new Paper.Path()
  //
  //     state.path.strokeColor = 'black';
  //     const point = new Paper.Point(e.layerX, e.layerY)
  //     state.path.moveTo(point)
  //     Paper.view.draw()
  //   }
  //   const onDrawEnd = (e) => {
  //     state.painting = false
  //     console.log('End drawing', e)
  //     state.path.simplify()
  //     state.segments = state.path.segments
  //     console.log('Submitting segments', toJS(state.segments))
  //     state.path = null
  //   }
  //   const onDrawMove = (e) => {
  //     if (!state.painting || !state.path) {
  //       return
  //     }
  //     const point = new Paper.Point(e.layerX, e.layerY)
  //     state.path.lineTo(point)
  //     Paper.view.draw()
  //   }
  //   canvas.addEventListener('pointerdown', onDrawStart)
  //   canvas.addEventListener('pointerup', onDrawEnd)
  //   canvas.addEventListener('pointermove', onDrawMove)
  //   return () => {
  //     canvas.removeListener(onDrawStart)
  //     canvas.removeListener(onDrawEnd)
  //     canvas.removeListener(onDrawMove)
  //   }
  // }, [])
  const viewportRef = React.useRef(null)
  const zoomIn = () => {
    console.log('Zooming In')
    viewportRef.current
      .zoomPercent(0.5, true)
  }
  const zoomOut = () => {
    console.log('Zooming out')
    viewportRef.current
      .zoomPercent(-0.5, true)
  }
  const follow = () => {
    const child = viewportRef.current.children.find(c => c.name === `player_${props.user.id}`)
    if (!child) {
      state.following = false
      return
    }
    if (!state.following) {
      state.following = true
      console.log('Follow', viewportRef.current)
      console.log(`Child for user ${props.user.id}`, viewportRef.current.children.find(c => c.name === `player_${props.user.id}`))
      viewportRef.current.follow(child, {
        speed: 20,
        acceleration: 5,
      })
    } else {
      viewportRef.current.follow(false)
      state.following = false
    }
  }
  const isLandscape = window.orientation === 90
  const onOrientationChange = () => {
    console.log('Orientation changed to', window.orientation)
    console.log(`Old width: ${state.stageWidth}, new width: ${window.innerWidth}`)
    const changedToLandscape = window.orientation === 90
    const width = window.innerHeight
    const height = window.innerWidth
    configureGameWindowSize(width, height)
    console.log(`Set new sizes: ${state.stageWidth}x${state.stageHeight} by ${window.innerWidth}x${window.innerHeight}`)
    const resizer = document.getElementById('resizer')
    state.app.resizeTo = resizer
    state.app.resize()
  }
  return useObserver(() => (
    <View id={props.id} header={state.activePanel === 'chat'} activePanel={state.activePanel}>
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
        {/*<canvas id="draw-field" width={state.stageWidth} height={state.stageHeight} ref={paintRef}>*/}

        {/*</canvas>*/}
        <div id="resizer" style={{ height: state.stageHeight, width: state.stageWidth, backgroundColor: 'transparent' }}>
          <Stage
            onMount={(a) => {
              const resizer = document.getElementById('resizer')
              a.resizeTo = resizer
              a.resize()
              a.smoothProperty = ''
              state.app = a
              window.addEventListener('orientationchange', onOrientationChange)
            }}
            onUnmount={() => {
              window.removeEventListener('orientationchange', onOrientationChange)
            }}
            options={{
              backgroundColor: 0x333333,
              antialias: true,
            }}
          >
            {
              state.fieldSettings && state.fieldSettings.length && state.game && state.app
                ? (
                  <ReactViewport
                    app={state.app}
                    ref={viewportRef}
                    pause={props.activeModal}
                    screenWidth={state.stageWidth}
                    screenHeight={state.stageHeight}
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
                      state.game.players.map((p, index) => {
                        const fieldPosition = state.fieldSettings[p.position]
                        const [positionX, positionY] = getPosition(fieldPosition.form, index)
                        const playerX = fieldPosition.point.x + positionX
                        const playerY = fieldPosition.point.y + positionY
                        return (
                          <PlayerSprite
                            name={`player_${p.player_id}`}
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
                            index={index}
                            player_id={p.player_id}
                            color={p.color}
                            position={p.position}
                            old_position={p.old_position}
                            enabled={enabled}
                            x={playerX}
                            y={playerY}
                          />
                        )
                      })
                    }
                    <Deck
                      round={10}
                      onSelectCard={(type) => {
                        props.setActiveOptionsModal('pick_event_card', {
                          ...state.game,
                          type,
                          onSubmit: async (data) => {
                            setTimeout(() => {
                              props.setActiveOptionsModal('confirm_event_card', {
                                event_card: state.game.event_cards.find(c => c.type === data.type),
                                game: state.game,
                                type,
                                onSubmit: async () => {
                                  console.log('Data at submit to event card action', data)
                                  gameChannel.push('action', data)
                                }
                              })
                            }, 0)
                          }
                        })
                      }}
                      event_cards={state.game.event_cards}
                    />
                    <Container
                      x={140}
                      y={800}
                    >
                      {
                        state.game.players.map((p, i) => {
                          const size = 80
                          return (
                            <Container
                              key={p.player_id}
                              x={i > 0 ? i * (size * 2) : 0}
                            >
                              <Container>
                                <Graphics
                                  preventRedraw
                                  draw={g => {
                                    g.clear()
                                    g.beginFill(0xffffff)
                                    g.drawRoundedRect(5, 4, size - 10, size - 8, 3)
                                    g.endFill()
                                  }}
                                />
                                <Graphics
                                  preventRedraw
                                  draw={g => {
                                    const color = colorString.to.hex(colorString.get.rgb(p.color || '#FFF'))
                                    g.clear()
                                    g.beginFill(Number(`0x${color.slice(1)}`), 0.3)
                                    g.drawRoundedRect(5, 4, size - 10, size - 8, 3)
                                    g.endFill()
                                  }}
                                />
                                <Sprite
                                  width={size}
                                  height={size}
                                  image={p.image_url || 'https://cdn.discord-underlords.com/eventcards/event-card-empty.png'}
                                />
                              </Container>
                              <Container
                                y={size + 10}
                              >
                                <Text
                                  x={0}
                                  y={0}
                                  visible={!p.surrender}
                                  text={p.name || `Игрок ${p.player_id}`}
                                  style={
                                    new PIXI.TextStyle({
                                      fontSize: 16,
                                      fill: '#FFF'
                                    })
                                  }
                                />
                                <Text
                                  x={0}
                                  y={24}
                                  visible={!p.surrender}
                                  text={`$ ${p.balance}`}
                                  style={
                                    new PIXI.TextStyle({
                                      fontSize: 16,
                                      fill: '#FFF'
                                    })
                                  }
                                />
                              </Container>
                            </Container>
                          )
                        })
                      }
                    </Container>
                  </ReactViewport>
                )
                : null
            }
            <Container
              name="user_info"
              x={isLandscape ? state.stageWidth - 32 : 0}
              y={isLandscape ? state.stageHeight - 32 - 16 : state.stageHeight - 32 - 40}
            >
              <Sprite
                visible={isLandscape}
                width={32}
                height={32}
                interactive
                image={props.user.image_url}
              />
              <Text
                resolution={6}
                visible={props.enabled}
                y={isLandscape ? 35 : 45}
                text={`$ 1000`}
                style={
                  new PIXI.TextStyle({
                    fill: 'white',
                    fontSize: 8,
                  })
                }
              />
            </Container>
            <Container
              name="action"
              y={isLandscape ? state.stageHeight - 32 : state.stageHeight - 32}
            >
              <Sprite
                x={(state.stageWidth - 32) / 2}
                y={0}
                width={32}
                height={32}
                interactive
                image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/dice1.png'}
              />
              <Sprite
                x={(state.stageWidth - 32) / 2}
                y={0}
                width={32}
                height={32}
                interactive
                image={'https://cdn.discord-underlords.com/icons/pay1.png'}
              />
              <Container>
                <Text
                  resolution={6}
                  visible={props.enabled}
                  x={3}
                  y={isLandscape ? state.stageHeight * -1 + 40 : 19}
                  text={`${state.timeLeft} сек`}
                  style={
                    new PIXI.TextStyle({
                      fill: 'white',
                      fontSize: 8,
                    })
                  }
                />
              </Container>
              <Sprite
                name="chat_button"
                visible={state.activePanel !== 'chat'}
                x={isLandscape ? 0 : state.stageWidth - 32}
                y={isLandscape ? 0 : 0}
                width={32}
                height={32}
                interactive={state.activePanel !== 'chat'}
                click={() => state.activePanel = 'chat'}
                tap={() => state.activePanel = 'chat'}
                image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/chat.png'}
              />
              <Sprite
                visible={state.activePanel === 'chat'}
                name="chat_button_active"
                x={isLandscape ? 0 : state.stageWidth - 32}
                y={isLandscape ? state.stageHeight - 32 : 0}
                width={32}
                height={32}
                image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/chat-active.png'}
              />
            </Container>
            <Container
              name="map_buttons"
              y={isLandscape ? 0 : state.stageHeight - 32 - 16 * 3 - 2 * 3}
            >
              <Sprite
                x={state.stageWidth - 16}
                y={0}
                width={16}
                height={16}
                interactive
                click={zoomIn}
                tap={zoomIn}
                image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/zoom-in.png'}
              />
              <Sprite
                x={state.stageWidth - 16}
                y={18}
                width={16}
                height={16}
                interactive
                click={zoomOut}
                tap={zoomOut}
                image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/zoom-out.png'}
              />
              <Sprite
                visible={!state.following}
                x={state.stageWidth - 16}
                y={36}
                width={16}
                height={16}
                interactive
                click={follow}
                tap={follow}
                image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/follow.png'}
              />
              <Sprite
                visible={state.following}
                x={state.stageWidth - 16}
                y={36}
                width={16}
                height={16}
                interactive
                click={follow}
                tap={follow}
                image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/follow-active.png'}
              />
            </Container>
          </Stage>
        </div>
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
