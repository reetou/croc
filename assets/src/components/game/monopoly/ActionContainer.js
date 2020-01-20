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
  const firstButtonPosition = {
    x: (state.stageWidth - 70) / 2,
    y: 0,
  }
  const secondButtonPosition = {
    x: (state.stageWidth - 70) / 2 + 38,
    y: 0
  }
  const chatSize = 24
  const chatButtonPosition = {
    x: isLandscape ? (state.stageWidth - chatSize) / 2 : state.stageWidth - chatSize,
    y: isLandscape ? (state.stageHeight - chatSize - 14) * -1 : (state.stageHeight - chatSize) / 2 * -1,
  }
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
      {/*<Sprite*/}
      {/*  visible={state.myTurn && state.eventType === 'pay'}*/}
      {/*  x={(state.stageWidth - 32) / 2}*/}
      {/*  y={0}*/}
      {/*  width={32}*/}
      {/*  height={32}*/}
      {/*  interactive*/}
      {/*  click={sendAction}*/}
      {/*  tap={sendAction}*/}
      {/*  image={'https://cdn.discord-underlords.com/icons/pay1.png'}*/}
      {/*/>*/}
      {/*<Sprite*/}
      {/*  visible={state.myTurn && state.eventType === 'free_card'}*/}
      {/*  x={firstButtonPosition.x}*/}
      {/*  y={firstButtonPosition.y}*/}
      {/*  width={32}*/}
      {/*  height={32}*/}
      {/*  interactive*/}
      {/*  click={sendAction}*/}
      {/*  tap={sendAction}*/}
      {/*  image={'https://cdn.discord-underlords.com/icons/buy.png'}*/}
      {/*/>*/}
      {/*<Sprite*/}
      {/*  visible={state.myTurn && state.eventType === 'free_card'}*/}
      {/*  x={secondButtonPosition.x}*/}
      {/*  y={secondButtonPosition.y}*/}
      {/*  width={32}*/}
      {/*  height={32}*/}
      {/*  interactive*/}
      {/*  click={sendAction}*/}
      {/*  tap={sendAction}*/}
      {/*  image={'https://cdn.discord-underlords.com/icons/reject.png'}*/}
      {/*/>*/}
      {/*<Sprite*/}
      {/*  visible={state.myTurn && state.eventType === 'auction'}*/}
      {/*  x={firstButtonPosition.x}*/}
      {/*  y={firstButtonPosition.y}*/}
      {/*  width={32}*/}
      {/*  height={32}*/}
      {/*  interactive*/}
      {/*  click={sendAction}*/}
      {/*  tap={sendAction}*/}
      {/*  image={'https://cdn.discord-underlords.com/icons/bid.png'}*/}
      {/*/>*/}
      {/*<Sprite*/}
      {/*  visible={state.myTurn && state.eventType === 'auction'}*/}
      {/*  x={secondButtonPosition.x}*/}
      {/*  y={secondButtonPosition.y}*/}
      {/*  width={32}*/}
      {/*  height={32}*/}
      {/*  interactive*/}
      {/*  click={sendAction}*/}
      {/*  tap={sendAction}*/}
      {/*  image={'https://cdn.discord-underlords.com/icons/reject.png'}*/}
      {/*/>*/}
      <Container
        y={isLandscape ? 0 : (state.stageHeight - 64) * -1}
        x={isLandscape ? 0 : 0}
      >
        <Sprite
          width={32}
          height={32}
          image={'https://cdn.discord-underlords.com/icons/timebg.png'}
        />
        <Text
          resolution={6}
          visible={props.enabled}
          x={7}
          y={19}
          text={`${state.timeLeft} с`}
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
        x={chatButtonPosition.x}
        y={chatButtonPosition.y}
        width={chatSize}
        height={chatSize}
        interactive={!state.chatActive}
        click={state.onOpenChat}
        tap={state.onOpenChat}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/chat.png'}
      />
      <Sprite
        visible={state.chatActive}
        name="chat_button_active"
        x={chatButtonPosition.x}
        y={chatButtonPosition.y}
        width={chatSize}
        height={chatSize}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/chat-active.png'}
      />
      <Sprite
        interactive
        x={state.stageWidth - 32}
        click={state.onSurrender}
        tap={state.onSurrender}
        name="surrender_button"
        width={24}
        height={24}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/surrender.png'}
      />
    </Container>
  )
}

export default ActionContainer
