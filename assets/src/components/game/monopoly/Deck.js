import { Sprite, Container } from '@inlet/react-pixi'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import React from 'react'
import { at, isInteger } from 'lodash-es'
import * as PIXI from 'pixi.js'

function Deck(props) {
  const emptyPlaceholder = 'https://cdn.discord-underlords.com/eventcards/event-card-empty.png'
  const state = useLocalStore(() => ({
    chosenIndex: null,
    texture: null,
    get currentCard() {
      if (!isInteger(this.chosenIndex)) {
        return null
      }
      return at(props, `event_cards.${this.chosenIndex}`)[0]
    }
  }))
  const noCards = !props.event_cards || props.event_cards.length === 0
  const canUse = props.round >= 10
  const getNextCard = () => {
    if (noCards) return
    const newIndex = state.chosenIndex + 1
    const index = newIndex < props.event_cards.length ? newIndex : 0
    state.chosenIndex = index
    state.texture = PIXI.Texture.from(state.currentCard.image_url)
  }
  const selectCard = () => {
    props.onSelectCard(state.currentCard.type)
  }
  return useObserver(() => (
    <Container
      x={234}
      y={248}
    >
      <Sprite
        width={256}
        height={256}
        interactive={canUse}
        click={getNextCard}
        tap={getNextCard}
        image={noCards || !canUse ? emptyPlaceholder : 'https://cdn.discord-underlords.com/eventcards/event-card-ph.png'}
      />
      <Container
        x={250}
      >
        <Sprite
          visible={state.currentCard}
          width={256}
          height={256}
          image={emptyPlaceholder}
        />
        {
          state.texture
            ? (
              <Sprite
                width={256}
                height={256}
                texture={state.texture}
                interactive={state.currentCard}
                click={selectCard}
                tap={selectCard}
              />
            )
            : null
        }
        <Sprite
          visible={!noCards && !state.currentCard}
          x={65}
          y={78}
          width={128}
          height={128}
          image={'https://cdn.discord-underlords.com/eventcards/event-card-inside-content.png'}
        />
      </Container>
    </Container>
  ))
}

export default Deck
