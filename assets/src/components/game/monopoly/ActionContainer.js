import { Sprite, Container, Text } from '@inlet/react-pixi'
import React from 'react'
import { useAsObservableSource } from 'mobx-react-lite'
import * as PIXI from "pixi.js"

function ActionContainer(props) {
  const state = useAsObservableSource(props)
  const {
    isLandscape,
    sendAction,
  } = state
  return (
    <Container
      name="action"
      y={isLandscape ? state.stageHeight - 32 : state.stageHeight - 32}
    >
      <Sprite
        visible={state.myTurn && state.eventType === 'roll'}
        x={(state.stageWidth - 32) / 2}
        y={0}
        width={32}
        height={32}
        interactive
        click={sendAction}
        tap={sendAction}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/dice1.png'}
      />
      <Sprite
        visible={state.myTurn && state.eventType === 'pay'}
        x={(state.stageWidth - 32) / 2}
        y={0}
        width={32}
        height={32}
        interactive
        click={sendAction}
        tap={sendAction}
        image={'https://cdn.discord-underlords.com/icons/pay1.png'}
      />
      <Container>
        <Text
          resolution={6}
          visible={props.enabled}
          x={3}
          y={isLandscape ? state.stageHeight * -1 + 40 : 19}
          text={`${state.timeLeft} сек`}
          style={
            new PIXI.TextStyle({
              fill: 'white',
              fontSize: 8,
            })
          }
        />
      </Container>
      <Sprite
        name="chat_button"
        visible={!state.chatActive}
        x={isLandscape ? 0 : state.stageWidth - 32}
        y={isLandscape ? 0 : 0}
        width={32}
        height={32}
        interactive={!state.chatActive}
        click={state.onOpenChat}
        tap={state.onOpenChat}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/chat.png'}
      />
      <Sprite
        visible={state.chatActive}
        name="chat_button_active"
        x={isLandscape ? 0 : state.stageWidth - 32}
        y={isLandscape ? state.stageHeight - 32 : 0}
        width={32}
        height={32}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/chat-active.png'}
      />
    </Container>
  )
}

export default ActionContainer
