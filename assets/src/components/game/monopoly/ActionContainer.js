import React, { useEffect, useState } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import { toJS } from 'mobx'
import { at } from 'lodash-es'
import CardPicker from './CardPicker'

function ActionContainer(props) {
  const state = useLocalStore(() => ({
    game: props.game,
    channel: props.channel,
    get myTurn() {
      if (!props.user) return false
      return state.game.player_turn === props.user.id
    },
    get me() {
      return state.game.players.find(p => p.player_id === props.user.id)
    },
    get playing() {
      return this.me && !this.me.surrender
    },
    get playerInCharge() {
      return state.game.players.find(p => state.game.player_turn === p.player_id)
    },
    get firstEventTurn() {
      if (!this.playerInCharge || !this.playerInCharge.events.length) return null
      const events = this.playerInCharge.events
        .slice()
        .sort((a, b) => a.priority - b.priority)
      console.log('Events', events.map(e => toJS(e)))
      return events[0]
    },
    get eventType() {
      return at(this, 'firstEventTurn.type')[0]
    },
    get currentCard() {
      return state.game.cards.find(c => c.position === this.playerInCharge.position)
    },
  }))
  useEffect(() => {
    state.game = props.game
    console.log('First event', toJS(state.firstEventTurn))
    if (state.myTurn) {
      document.title = 'Вы ходите'
    } else {
      document.title = 'Игра'
    }
    console.log('Game', toJS(props.game))
  }, [props.game])
  useEffect(() => {
    state.channel = props.channel
  }, [props.channel])
  const sendAction = () => {
    if (!state.channel) {
      throw new Error('No channel passed to action container')
    }
    if (!state.firstEventTurn) {
      throw new Error('No events at player')
    }
    state.channel.push('action', {
      type: state.firstEventTurn.type,
      event_id: state.firstEventTurn.event_id,
    })
  }
  const sendMessage = () => {
    state.channel.push('chat_message', {
      text: "Shit",
      to: null,
      chat_id: props.game.chat_id
    })
  }
  const sendPrivateMessage = () => {
    state.channel.push('chat_message', {
      text: "Personal message yo",
      to: 17,
      chat_id: props.game.chat_id
    })
  }
  const sendBuy = () => {
    state.channel.push('action', {
      type: 'buy',
      event_id: state.firstEventTurn.event_id,
    })
  }
  const sendRejectBuy = () => {
    state.channel.push('action', {
      type: 'reject_buy',
      event_id: state.firstEventTurn.event_id,
    })
  }
  const sendSurrender = () => {
    state.channel.push('action', {
      type: 'surrender',
    })
  }
  const sendAuctionAction = (bid = true) => {
    state.channel.push('action', {
      type: bid ? 'auction_bid' : 'auction_reject',
      event_id: state.firstEventTurn.event_id
    })
  }
  const sendCardAction = (type, position) => {
    state.channel.push('action', {
      type,
      position,
    })
  }
  return useObserver(() => (
    <div>
      {
        props.card ?
          <CardPicker
            user={props.user}
            onUpgrade={() => { sendCardAction('upgrade', props.card.position) }}
            onDowngrade={() => { sendCardAction('downgrade', props.card.position) }}
            onBuyout={() => { sendCardAction('buyout', props.card.position) }}
            onPutOnLoan={() => { sendCardAction('put_on_loan', props.card.position) }}
            card={props.card}
          />
          : null
      }
      {
        state.playing
          ? (
            <button onClick={sendSurrender}>Surrender</button>
          )
          : (
            <h1>You are not playing anymore</h1>
          )
      }
      {
        state.myTurn
          ? (
            <div>
              <h1>Вы ходите...</h1>
              {
                state.eventType === 'roll' || state.eventType === 'pay'
                  ? (
                    <button onClick={sendAction}>Send action {state.eventType}</button>
                  )
                  : null
              }
              {
                state.eventType === 'free_card'
                  ? (
                    <div>
                      <button onClick={sendBuy}>Купить {state.currentCard.name} за {state.currentCard.cost}k</button>
                      <button style={{ marginLeft: 10 }} onClick={sendRejectBuy}>Выставить на аукцион</button>
                    </div>
                  )
                  : null
              }
              {
                state.eventType === 'auction'
                  ? (
                    <div>
                      <button onClick={sendAuctionAction}>Поднять цену до {at(state, 'firstEventTurn.amount')[0]}k</button>
                      <button style={{ marginLeft: 10 }} onClick={() => sendAuctionAction(false)}>Отказаться от аукциона</button>
                    </div>
                  )
                  : null
              }
            </div>
          )
          : (
            <h1>{at(state, 'firstEventTurn.text')[0]} {at(state, 'playerInCharge.player_id')[0]}</h1>
          )
      }
      <button onClick={sendMessage}>Send message</button>
      <button onClick={sendPrivateMessage}>Send PRIVATE message</button>
    </div>
  ))
}

export default ActionContainer
