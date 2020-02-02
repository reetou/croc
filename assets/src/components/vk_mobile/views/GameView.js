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
import { getCompletedMonopolies, getPosition } from '../../../util'
import useChannel from '../../../useChannel'
import { toJS } from 'mobx'
import ReactViewport from '../../ReactViewport'
import Deck from '../../game/monopoly/Deck'
import colorString from 'color-string'
import ActionContainer from '../../game/monopoly/ActionContainer'
import MapButtonsContainer from '../../game/monopoly/MapButtonsContainer'
import RulesPanel from '../panels/RulesPanel'
import * as PIXI from 'pixi.js'
import connect from '@vkontakte/vk-connect'
window.PIXI = PIXI;
require("pixi-compressed-textures")
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
    get myTurn() {
      if (!source.user || !this.game) return false
      const isMyTurn = this.game.player_turn === source.user.id
      return isMyTurn
    },
    get me() {
      if (!this.game) {
        return null
      }
      const player = this.game.players.find(p => p.player_id === source.user.id)
      if (!player) {
        return null
      }
      return player
    },
    get playing() {
      return this.me && !this.me.surrender
    },
    get playerInCharge() {
      if (!this.game) return null
      return this.game.players.find(p => this.game.player_turn === p.player_id)
    },
    get firstEventTurn() {
      if (!this.playerInCharge || !this.playerInCharge.events.length) return null
      const events = this.playerInCharge.events
        .slice()
        .sort((a, b) => a.priority - b.priority)
      console.log('Events', events.map(e => toJS(e)))
      return events[0]
    },
    get myFirstEventTurn() {
      if (!this.playerInCharge || !this.playerInCharge.events.length) return null
      const events = this.playerInCharge.events
        .slice()
        .sort((a, b) => a.priority - b.priority)
      console.log('Events', events.map(e => toJS(e)))
      if (!this.myTurn) return null
      return events[0]
    },
    get eventType() {
      if (!this.myFirstEventTurn) return false
      return this.myFirstEventTurn.type
    },
    get eventCard() {
      if (!this.myFirstEventTurn || !this.myFirstEventTurn.position) {
        return false
      }
      return this.game.cards.find(c => c.position === this.myFirstEventTurn.position)
    },
    get currentCard() {
      return this.game.cards.find(c => c.position === this.playerInCharge.position)
    },
    now: Date.now(),
    get timeLeft() {
      if (!this.game) return -1
      if (!this.game.turn_timeout_at) return -1
      const timeoutTime = new Date(this.game.turn_timeout_at).getTime()
      if (this.now > timeoutTime) return 0
      return parseInt((timeoutTime - this.now) / 1000, 10)
    },
    get ownedCards() {
      return this.game.cards.filter(c => c.owner === this.me.player_id)
    },
    get cardsOnLoan() {
      return this.ownedCards.filter(c => c.on_loan)
    },
    get activeCards() {
      return this.ownedCards.filter(c => !c.on_loan)
    },
    get completedMonopolies() {
      return getCompletedMonopolies(this.game.cards)
    },
    get upgradableCards() {
      return this.completedMonopolies
        .filter(c => c.owner === this.me.player_id && !c.on_loan)
    },
    get downgradableCards() {
      return this.activeCards.filter(c => c.upgrade_level > 0)
    }
  }), props)
  useEffect(() => {
    const interval = setInterval(() => {
      state.now = Date.now()
    }, 1000)
    return () => {
      clearInterval(interval)
    }
  }, [])
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
  const userChannelName = `user:${props.user ? props.user.id : 'noop'}`
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
    const tabbarHeight = 3
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
    if (state.app) {
      state.app.resize()
    }
  }, [state.stageHeight])
  const [userChannel] = useChannel(userChannelName, onJoin)
  const sendAction = () => {
    if (!gameChannel) {
      throw new Error('No channel passed to action container')
    }
    if (!state.myFirstEventTurn) {
      throw new Error('No events at player')
    }
    console.log(`Gonna send action`, {
      type: state.myFirstEventTurn.type,
      event_id: state.myFirstEventTurn.event_id,
    })
    gameChannel.push('action', {
      type: state.myFirstEventTurn.type,
      event_id: state.myFirstEventTurn.event_id,
    })
  }
  const sendSurrender = () => {
    gameChannel.push('action', {
      type: 'surrender',
    })
    connect.send('VKWebAppTapticImpactOccurred', {style: 'heavy'})
  }
  const surrender = () => {
    props.setActiveOptionsModal('confirm_surrender', {
      onSubmit: sendSurrender
    })
  }
  useEffect(() => {
    if (!state.playing) {
      state.activePanel = 'no_game'
      state.game = null
      props.onSurrender()
    }
  }, [state.playing])
  const pickField = (type) => {
    const defaultParams = {
      type,
      onSubmit: async ({ type, position }) => {
        gameChannel.push('action', {
          type,
          position,
        })
      }
    }
    switch (type) {
      case 'put_on_loan':
        return props.setActiveOptionsModal('pick_field', {
          cards: state.activeCards,
          ...defaultParams
        })
      case 'buyout':
        return props.setActiveOptionsModal('pick_field', {
          cards: state.cardsOnLoan,
          ...defaultParams
        })
      case 'upgrade':
        return props.setActiveOptionsModal('pick_field', {
          cards: state.upgradableCards,
          ...defaultParams
        })
      case 'downgrade':
        return props.setActiveOptionsModal('pick_field', {
          cards: state.downgradableCards,
          ...defaultParams
        })
    }
  }
  const sendBuy = () => {
    gameChannel.push('action', {
      type: 'buy',
      event_id: state.myFirstEventTurn.event_id,
    })
  }
  const sendRejectBuy = () => {
    gameChannel.push('action', {
      type: 'reject_buy',
      event_id: state.myFirstEventTurn.event_id,
    })
  }
  const sendAuctionAction = (bid = true) => {
    gameChannel.push('action', {
      type: bid ? 'auction_bid' : 'auction_reject',
      event_id: state.firstEventTurn.event_id
    })
  }
  const chooseAction = () => {
    const loanAction = {
      onClick: () => {
        props.setActiveModal('', null)
        setTimeout(() => {
          pickField('put_on_loan')
        }, 150)
      },
      text: 'Заложить поле'
    }
    const downgradeAction = {
      onClick: () => {
        props.setActiveModal('', null)
        setTimeout(() => {
          pickField('downgrade')
        }, 150)
      },
      text: 'Продать филиал'
    }
    switch (state.eventType) {
      case 'free_card':
        const freeCard = state.game.cards.find(c => c.position === state.firstEventTurn.position)
        return props.setActiveOptionsModal('choose_action', {
          title: 'Вы попали на свободное поле',
          card: freeCard,
          cost: freeCard ? freeCard.cost : null,
          actions: [
            {
              text: `Купить за ${state.game.cards.find(c => c.position === state.firstEventTurn.position).cost}`,
              onClick: sendBuy
            },
            {
              text: 'Выставить на аукцион',
              onClick: sendRejectBuy
            },
            ...state.activeCards.length ? [loanAction] : [],
            ...state.downgradableCards.length ? [downgradeAction] : [],
          ]
        })
        return
      case 'auction':
        const auctionCard = state.game.cards.find(c => c.position === state.firstEventTurn.position)
        return props.setActiveOptionsModal('choose_action', {
          title: 'Аукцион',
          card: auctionCard,
          cost: auctionCard ? state.firstEventTurn.amount : null,
          actions: [
            {
              text: `Поднять ставку до $ ${state.firstEventTurn.amount}`,
              onClick: () => sendAuctionAction(true)
            },
            {
              text: `Отказаться от аукциона`,
              onClick: () => sendAuctionAction(false)
            },
            ...state.activeCards.length ? [loanAction] : [],
            ...state.downgradableCards.length ? [downgradeAction] : [],
          ]
        })
      case 'pay':
        return props.setActiveOptionsModal('choose_action', {
          title: 'Нужно заплатить',
          actions: [
            {
              text: `Заплатить ${state.firstEventTurn.amount}`,
              onClick: sendAction
            },
            ...state.activeCards.length ? [loanAction] : [],
            ...state.downgradableCards.length ? [downgradeAction] : [],
          ]
        })
      default: return null
    }
  }
  useEffect(() => {
    if (!gameChannel) {
      console.log('No game channel, returning')
      return
    }
    //the LOAD_SCREENSHOT_MESSAGE is a message defined by the server
    gameChannel.on('game_update', payload => {
      console.log('Payload at game update', payload)
      state.game = payload.game
      if (state.game.player_turn === props.user.id) {
        connect.send('VKWebAppTapticImpactOccurred', {style: 'heavy'})
        props.setActiveModal('', null)
        setTimeout(chooseAction, 1000)
      }
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
  const showHeader = ['chat', 'rules'].includes(state.activePanel)
  return useObserver(() => (
    <View id={props.id} header={showHeader} activePanel={state.activePanel}>
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
              resolution: window.devicePixelRatio || 1,
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
                    pause={props.activeModal || state.activePanel !== 'game'}
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
              x={isLandscape ? 0 : 0}
              y={isLandscape ? 8 : 8}
            >
              <Sprite
                visible={isLandscape}
                width={32}
                height={32}
                interactive
                image={props.user && props.user.image_url ? props.user.image_url : 'https://cdn.discord-underlords.com/eventcards/event-card-empty.png'}
              />
              {
                state.me
                  ? (
                    <Text
                      resolution={ 6 }
                      visible={ props.enabled }
                      y={ isLandscape ? 35 : 0 }
                      text={`$ ${state.me.balance}`}
                      style={
                        new PIXI.TextStyle({
                          fill: 'white',
                          fontSize: 8,
                        })
                      }
                    />
                  )
                  : null
              }
            </Container>
            <MapButtonsContainer
              isLandscape={isLandscape}
              stageHeight={state.stageHeight}
              stageWidth={state.stageWidth}
              zoomIn={zoomIn}
              zoomOut={zoomOut}
              follow={follow}
              following={state.following}
            />
            <ActionContainer
              chooseAction={chooseAction}
              isLandscape={isLandscape}
              stageHeight={state.stageHeight}
              stageWidth={state.stageWidth}
              sendAction={sendAction}
              onSurrender={surrender}
              myTurn={state.myTurn}
              eventType={state.eventType}
              onOpenChat={() => state.activePanel = 'chat'}
              onOpenRules={() => state.activePanel = 'rules'}
              chatActive={state.activePanel === 'chat'}
              timeLeft={state.timeLeft}
            />
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
      <Panel id={'rules'}>
        <Suspense fallback={<ScreenSpinner size="large" />}>
          <RulesPanel
            onGoBack={() => {
              state.activePanel = 'game'
            }}
          />
        </Suspense>
      </Panel>
    </View>
  ))
}

export default GameView
