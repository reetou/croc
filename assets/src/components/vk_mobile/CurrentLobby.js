import React, { useEffect } from 'react'
import { useObserver } from 'mobx-react-lite'
import { Panel, PanelHeader } from '@vkontakte/vkui'

function CurrentLobby(props) {
  if (!props.lobby) return null
  return useObserver(() => (
    <Panel id={props.id}>
      <PanelHeader>Игра {props.lobby.lobby_id}</PanelHeader>
    </Panel>
  ))
}

export default CurrentLobby
