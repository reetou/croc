import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import styled from 'styled-components'

const Container = styled.div`
  display: flex;
  flex-direction: column;
  padding: 1rem;
  border: 1px solid black;
`

const CardName = styled.div`
  font-size: 1.1rem;
  font-weight: bold;
`

function CardPicker(props) {
  const state = useLocalStore(() => ({
    card: null,
    get owner() {
      if (!this.card || !this.card.owner) return false
      return this.card.owner === props.user.id
    },
    get upgradable() {
      if (!this.card || !this.owner) return false
      return this.card.upgrade_level < this.card.max_upgrade_level && this.card.type === 'brand'
    },
    get downgradable() {
      if (!this.card || !this.owner) return false
      return this.card.upgrade_level > 0 && this.card.type === 'brand'
    },
    get sellable() {
      if (!this.card || !this.owner) return false
      return this.card.owner && this.card.type === 'brand' && this.card.on_loan !== true
    },
    get can_buyout() {
      if (!this.card || !this.owner) return false
      return this.card.owner && this.card.type === 'brand' && this.card.on_loan === true
    },
  }))
  useEffect(() => {
    console.log('Props card', props.card)
    state.card = props.card
  }, [props.card])
  return useObserver(() => (
    <Container>
      {
        state.card
          ? (
            <React.Fragment>
              <CardName>{state.card.name}</CardName>
              { state.card.owner ? <div>Owner: {state.card.owner}</div> : <div>No owner</div> }
              { state.card.on_loan ? <div>ON LOAN</div> : null }
              { state.upgradable ? <button onClick={props.onUpgrade}>Upgrade</button> : null }
              { state.downgradable ? <button onClick={props.onDowngrade}>Downgradable</button> : null }
              { state.sellable ? <button onClick={props.onPutOnLoan}>Put on loan</button> : null }
              { state.can_buyout ? <button onClick={props.onBuyout}>Buyout</button> : null }
            </React.Fragment>
          )
          : null
      }
    </Container>
  ))
}

export default CardPicker
