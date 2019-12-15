import React from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import styled from 'styled-components'

const Container = styled.div`
  border-radius: 5px;
  background-color: ${({ color }) => color};
  width: 30px;
  height: 30px;
  border: 1px solid white;
`

function Player(props) {
  return useObserver(() => (
    <Container color={props.player.color} />
  ))
}

export default Player
