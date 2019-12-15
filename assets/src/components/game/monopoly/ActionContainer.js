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
    get playerInCharge() {
      return state.game.players.find(p => state.game.player_turn === p.player_id)
    },
    get firstEventTurn() {
      if (!this.playerInCharge.events.length) return null
      const events = this.playerInCharge.events
        .slice()
        .sort((a, b) => a.priority - b.priority)
      console.log('Events', events.map(e => toJS(e)))
      return events[0]
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
  const eventType = at(state, 'firstEventTurn.type')[0]
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
      <p>Event {state.firstEventTurn ? state.firstEventTurn.event_id : 'no event'}</p>
      {
        state.myTurn
          ? (
            <div>
              <h1>Вы ходите...</h1>
              {
                eventType === 'roll' || eventType === 'pay'
                  ? (
                    <button onClick={sendAction}>Send action {eventType}</button>
                  )
                  : null
              }
              {
                eventType === 'free_card'
                  ? (
                    <div>
                      <button onClick={sendBuy}>Купить {state.currentCard.name} за {state.currentCard.cost}k</button>
                      <button style={{ marginLeft: 10 }} onClick={sendRejectBuy}>Выставить на аукцион</button>
                    </div>
                  )
                  : null
              }
              {
                eventType === 'auction'
                  ? (
                    <div>
                      <button onClick={sendAuctionAction}>Поднять цену до {state.firstEventTurn.amount}k</button>
                      <button style={{ marginLeft: 10 }} onClick={() => sendAuctionAction(false)}>Отказаться от аукциона</button>
                    </div>
                  )
                  : null
              }
            </div>
          )
          : (
            <h1>{state.firstEventTurn.text} {state.playerInCharge.player_id}</h1>
          )
      }
    </div>
  ))
}

export default ActionContainer
