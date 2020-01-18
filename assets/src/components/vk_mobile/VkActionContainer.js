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
import { getCompletedMonopolies } from '../../util'

function VkActionContainer(props, ref) {
  const { gameChannel, setActiveOptionsModal } = props
  const state = useLocalStore((source) => ({
    game: source.game,
    get myTurn() {
      if (!source.user) return false
      const isMyTurn = this.game.player_turn === source.user.id
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
        return setActiveOptionsModal('pick_field', {
          cards: state.activeCards,
          ...defaultParams
        })
      case 'buyout':
        return setActiveOptionsModal('pick_field', {
          cards: state.cardsOnLoan,
          ...defaultParams
        })
      case 'upgrade':
        return setActiveOptionsModal('pick_field', {
          cards: state.upgradableCards,
          ...defaultParams
        })
      case 'downgrade':
        return setActiveOptionsModal('pick_field', {
          cards: state.downgradableCards,
          ...defaultParams
        })
    }
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
  return useObserver(() => (
    <div ref={ref}>
      <Group id="action_container">
        {
          state.playerInCharge && !state.myTurn
            ? (
              <Div>
                <InfoRow header={`${state.playerInCharge.name} ${state.firstEventTurn.text}`}>
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
          <Div>
            <Button
              onClick={sendAction}
              disabled={Boolean((state.eventType === 'roll' || state.eventType === 'pay') && state.myTurn) === false}
            >
              Бросить кубики
            </Button>
          </Div>
          {
            state.eventType === 'pay' && state.myTurn
              ? (
                <Div>
                  <Button
                    onClick={sendAction}
                    disabled={Boolean((state.eventType === 'roll' || state.eventType === 'pay') && state.myTurn) === false}
                  >
                    {state.eventType === 'roll' ? 'Бросить кубики' : 'Заплатить'}
                  </Button>
                </Div>
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
          {
            state.myTurn
              ? (
                <React.Fragment>
                  {
                    state.cardsOnLoan.length
                      ? (
                        <Div>
                          <Button onClick={() => pickField('buyout')}>Выкупить поле</Button>
                        </Div>
                      )
                      : null
                  }
                  {
                    state.activeCards.length
                      ? (
                        <Div>
                          <Button onClick={() => pickField('put_on_loan')}>Заложить поле</Button>
                        </Div>
                      )
                      : null
                  }
                  {
                    state.upgradableCards.length
                      ? (
                        <Div>
                          <Button onClick={() => pickField('upgrade')}>Построить филиал</Button>
                        </Div>
                      )
                      : null
                  }
                  {
                    state.downgradableCards.length
                      ? (
                        <Div>
                          <Button onClick={() => pickField('downgrade')}>Продать филиал</Button>
                        </Div>
                      )
                      : null
                  }
                </React.Fragment>
              )
              : null
          }
        </Tabs>
      </Group>
    </div>
  ))
}

export default React.forwardRef(VkActionContainer)
