import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import styled from 'styled-components'
import { toJS } from 'mobx'
import _ from 'lodash-es'
import Player from './Player'

const Container = styled.div`
  display: flex;
`

const CardColumn = styled.div`
  display: flex;
  flex-direction: column;
`

const CardRow = styled.div`
  display: flex;
`

const CardRowContainer = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: space-between;
`

const getWidth = (square, vertical) => {
  if (square) return 110
  if (vertical) return 60
  return 110
}

const getHeight = (square, vertical) => {
  if (square) return 110
  if (vertical) return 110
  return 40
}

const CardContainer = styled.div`
  position: relative;
  width: ${({ vertical, square }) => getWidth(square, vertical)}px;
  height: ${({ vertical, square }) => getHeight(square, vertical)}px;
  background-color: ${({ color }) => color || '#eee'};
  opacity: ${({ on_loan }) => on_loan ? '0.5' : '1'};
`

const PlayerPositionContainer = styled.div`
  display: flex;
  flex-direction: ${({ vertical }) => vertical ? 'column' : 'row'};
`

function Card(props) {
  const color = props.ownerPlayer ? props.ownerPlayer.color : null
  return (
    <CardContainer {...props} color={color}>
      <p style={{ position: 'absolute' }}>{props.name} [{props.position}]</p>
      {props.children}
    </CardContainer>
  )
}

function PlayerPosition(props) {
  return useObserver(() => (
    <PlayerPositionContainer {...props}>
      {
        props.positions.map(player_id => {
          const player = props.game.players.find(p => p.player_id == player_id)
          return (
            <Player key={player_id} player={player} />
          )
        })
      }
    </PlayerPositionContainer>
  ))
}

function HorizontalCards(props) {
  return useObserver(() => (
    <React.Fragment>
      {
        props.cards.map((c, i, arr) => {
          const owner = props.game.players.find(p => p.player_id === c.owner)
          const square = i === 0 || i === (arr.length - 1)
          return (
            <Card
              onClick={() => props.onCardClick(c)}
              key={c.id}
              square={square}
              ownerPlayer={owner}
              {...c}
            >
              <PlayerPosition
                vertical={square}
                game={props.game}
                positions={props.playerPositions[c.position]}
              />
            </Card>
          )
        })
      }
    </React.Fragment>
  ))
}

function VerticalCards(props) {
  return useObserver(() => (
    <React.Fragment>
      {
        props.cards.map((c, i, arr) => {
          const owner = props.game.players.find(p => p.player_id === c.owner)
          return (
            <Card
              onClick={() => props.onCardClick(c)}
              key={c.id}
              vertical
              ownerPlayer={owner}
              {...c}
            >
              <PlayerPosition
                vertical
                game={props.game}
                positions={props.playerPositions[c.position]}
              />
            </Card>
          )
        })
      }
    </React.Fragment>
  ))
}

function MonopolyTable(props) {
  const state = useLocalStore(() => ({
    game: props.game,
    get playerInCharge() {
      return state.game.players.find(p => state.game.player_turn === p.player_id)
    },
    get playerPositions() {
      const positions = state.game.cards.map(c => {
        const players = state.game.players.filter(p => p.position === c.position).map(p => p.player_id)
        return players
      })
      return positions
    }
  }))
  useEffect(() => {
    state.game = props.game
  }, [props.game])
  const leftColumnPositions = [0, 39, 38, 37, 36, 35, 34, 33, 32, 31, 30]
  const rightColumnPositions = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
  const topRowPositions = [1, 2, 3, 4, 5, 6, 7, 8, 9]
  const bottomRowPositions = [21, 22, 23, 24, 25, 26, 27, 28, 29]
  const leftColumnCards = state.game.cards
    .filter(c => leftColumnPositions.includes(c.position))
    .sort((a, b) => {
      if (b.position === 0) {
        return 99999
      }
      const r = b.position - a.position
      return r
    })
  const rightColumnCards = state.game.cards
    .filter(c => rightColumnPositions.includes(c.position))
    .sort((a, b) => a.position - b.position)
  const topRowCards = state.game.cards
    .filter(c => topRowPositions.includes(c.position))
    .sort((a, b) => a.position - b.position)
  const bottomRowCards = state.game.cards
    .filter(c => bottomRowPositions.includes(c.position))
    .sort((a, b) => {
      return b.position - a.position
    })
  return useObserver(() => (
    <div>
      <Container>
        <CardColumn>
          <HorizontalCards
            game={props.game}
            cards={leftColumnCards}
            playerPositions={state.playerPositions}
            onCardClick={props.onCardClick}
          />
        </CardColumn>
        <CardRowContainer>
          <CardRow>
            <VerticalCards
              game={props.game}
              cards={topRowCards}
              playerPositions={state.playerPositions}
              onCardClick={props.onCardClick}
            />
          </CardRow>
          <CardRow>
            <VerticalCards
              game={props.game}
              cards={bottomRowCards}
              playerPositions={state.playerPositions}
              onCardClick={props.onCardClick}
            />
          </CardRow>
        </CardRowContainer>
        <CardColumn>
          <HorizontalCards
            game={props.game}
            cards={rightColumnCards}
            playerPositions={state.playerPositions}
            onCardClick={props.onCardClick}
          />
        </CardColumn>
      </Container>
    </div>
  ))
}

export default MonopolyTable
