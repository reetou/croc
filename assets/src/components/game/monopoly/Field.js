import { useApp, Sprite, Container, Text, Graphics } from '@inlet/react-pixi'
import { useObserver } from 'mobx-react-lite'
import React, { useState, useEffect, useRef } from 'react'
import * as PIXI from 'pixi.js'
import colorString from 'color-string'

const getWidth = (form) => {
  switch (form) {
    case 'vertical': return 60
    default: return 110
  }
}

const getHeight = (form) => {
  switch (form) {
    case 'vertical':
    case 'square': return 110
    default: return 40
  }
}

function Field(props) {
  const app = useApp()
  const [moving, setMoving] = useState(false)
  const [x, setX] = useState(props.x || 100)
  const [y, setY] = useState(props.y || 100)
  const fieldRef = useRef(null)
  useEffect(() => {
    if (!moving) {
      props.onSubmitPoint([x, y])
    }
  }, [moving])
  useEffect(() => {
    setMoving(false)
  }, [props.enabled])
  return useObserver(() => (
    <Container
      x={x}
      y={y}
      anchor={0.5}
      width={getWidth(props.form)}
      height={getHeight(props.form)}
      ref={fieldRef}
      name={`card_${props.card.name}`}
      interactive
      click={(e) => {
        if (props.enabled) {
          setMoving(!moving)
        }
        if (props.click) {
          props.click()
        }
      }}
      mousemove={(e) => {
        if (!moving || !props.enabled) return
        setX(e.data.global.x)
        setY(e.data.global.y)
      }}
    >
      <Sprite
        image="https://s3-us-west-2.amazonaws.com/s.cdpn.io/693612/coin.png"
        width={getWidth(props.form)}
        height={getHeight(props.form)}
        anchor={0.5}
        alpha={moving ? 0.6 : 1}
      />
      <Container
        anchor={1}
        visible={Boolean(props.color)}
      >
        <Graphics
          preventRedraw
          alpha={0.5}
          draw={g => {
            g.clear()
            const color = colorString.to.hex(colorString.get.rgb(props.color || 'red'))
            g.beginFill(Number(`0x${color.slice(1)}`))
            const width = getWidth(props.form)
            const height = getHeight(props.form)
            g.drawRect(width / 2 * -1, height / 2 * -1, width, height)
            g.endFill()
          }}
        />
      </Container>
      <Text
        visible={props.enabled}
        x={0}
        y={0}
        anchor={0.5}
        text={props.card.position}
        style={
          new PIXI.TextStyle({
            fill: ['red'],
            stroke: 'white',
            strokeThickness: 3,
          })
        }
      />
    </Container>
  ))
}

export default Field
