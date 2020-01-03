import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import { toJS } from 'mobx'
import {
  Div,
  Button,
  Group,
  Tabs,
  InfoRow,
  Progress,
} from '@vkontakte/vkui'

function VkActionContainer(props) {
  const { gameChannel, setActiveOptionsModal } = props
  const state = useLocalStore((source) => ({
    game: source.game,
    get myTurn() {
      if (!source.user) return false
      const isMyTurn = this.game.player_turn === source.user.id
      console.log('Player turn is mine???', isMyTurn)
      return isMyTurn
    },
    get me() {
      return this.game.players.find(p => p.player_id === source.user.id)
    },
    get playing() {
      return this.me && !this.me.surrender
    },
    get playerInCharge() {
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
      if (!this.game.turn_timeout_at) return -1
      const timeoutTime = new Date(this.game.turn_timeout_at).getTime()
      if (this.now > timeoutTime) return 0
      return parseInt((timeoutTime - this.now) / 1000, 10)
    },
    get timeLeftProgress() {
      const turnStart = new Date(this.game.turn_started_at).getTime()
      const turnTimeout = new Date(this.game.turn_timeout_at).getTime()
      const totalTurnTime = parseInt((turnTimeout - turnStart) / 1000, 10)
      if (this.timeLeft <= 0) return 0
      const progress = this.timeLeft * 100 / totalTurnTime
      return progress
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
    state.game = props.game
  }, [props.game])
  const sendAction = () => {
    if (!gameChannel) {
      throw new Error('No channel passed to action container')
    }
    if (!state.myFirstEventTurn) {
      throw new Error('No events at player')
    }
    gameChannel.push('action', {
      type: state.myFirstEventTurn.type,
      event_id: state.myFirstEventTurn.event_id,
    })
  }
  const sendMessage = () => {
    gameChannel.push('chat_message', {
      text: "Shit",
      to: null,
      chat_id: state.game.chat_id
    })
  }
  const sendPrivateMessage = () => {
    gameChannel.push('chat_message', {
      text: "Personal message yo",
      to: 17,
      chat_id: state.game.chat_id
    })
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
  const requestFreeCardAction = () => {
    setActiveOptionsModal('free_card_action', {
      title: `Что делать с полем ${state.currentCard.name}`,
      onBuy: sendBuy,
      onRejectBuy: sendRejectBuy,
    })
  }
  const requestAuctionAction = () => {
    setActiveOptionsModal('auction_action', {
      title: `${state.eventCard.position} на аукционе!`,
      event: state.myFirstEventTurn,
      onBid: sendAuctionAction,
      onReject: () => sendAuctionAction(false)
    })
  }
  const sendSurrender = () => {
    gameChannel.push('action', {
      type: 'surrender',
    })
  }
  const sendAuctionAction = (bid = true) => {
    gameChannel.push('action', {
      type: bid ? 'auction_bid' : 'auction_reject',
      event_id: state.myFirstEventTurn.event_id
    })
  }
  const sendCardAction = (type, position) => {
    gameChannel.push('action', {
      type,
      position,
    })
  }
  const openGameDeck = () => {
    console.log('State game', toJS(state.game))
    props.setActiveOptionsModal('pick_event_card', {
      ...state.game,
      onSubmit: async (data) => {
        console.log('Data at submit to event card action', data)
        gameChannel.push('action', data)
      }
    })
  }
  return useObserver(() => (
    <Group>
      {
        state.playerInCharge && !state.myTurn
          ? (
            <Div>
              <InfoRow header={`${state.playerInCharge.player_id} ${state.firstEventTurn.text}`}>
                <Progress value={state.timeLeftProgress} />
              </InfoRow>
            </Div>
          )
          : null
      }
      {
        state.myTurn
          ? (
            <Div>
              <InfoRow header="Вы ходите">
                <Progress value={state.timeLeftProgress} />
              </InfoRow>
            </Div>
          )
          : null
      }
      <Tabs type="buttons">
        {
          (state.eventType === 'roll' || state.eventType === 'pay') && state.myTurn
            ? (
              <React.Fragment>
                <Div>
                  <Button onClick={sendAction}>Send action {state.eventType}</Button>
                </Div>
                <Div>
                  <Button
                    onClick={openGameDeck}
                  >
                    Вытянуть карту из колоды
                  </Button>
                </Div>
              </React.Fragment>
            )
            : null
        }
        {
          state.eventType === 'free_card'
            ? (
              <Div>
                <Button onClick={requestFreeCardAction}>Можно купить: {state.currentCard.name}</Button>
              </Div>
            )
            : null
        }
        {
          state.eventType === 'auction'
            ? (
              <Div>
                <Button onClick={requestAuctionAction}>Аукцион: {state.eventCard.name}</Button>
              </Div>
            )
            : null
        }
      </Tabs>
    </Group>
  ))
}

export default VkActionContainer
