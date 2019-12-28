import { useApp, Sprite, Container, Text, Graphics } from '@inlet/react-pixi'
import { useObserver } from 'mobx-react-lite'
import React, { useState, useEffect, useRef } from 'react'
import * as PIXI from 'pixi.js'
import colorString from 'color-string'
import {
  getMobileWidth,
  getMobileHeight,
  getWidth,
  getHeight,
} from '../../../util'


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
  const onClick = (e) => {
    if (props.enabled) {
      setMoving(!moving)
    }
    if (props.click) {
      props.click()
    }
  }
  const onTouchStart = (e) => {
    if (props.click) {
      props.click()
    }
    if (!props.enabled) return
    if (props.enabled) {
      setMoving(true)
    }
  }
  const onTouchEnd = (e) => {
    if (!props.enabled) return
    const newX = e.data.global.x
    const newY = e.data.global.y
    console.log(`Touch end: x: ${newX}, y: ${newY}`)
    setX(newX)
    setY(newY)
    setMoving(false)
  }
  const onMove = (e) => {
    if (!moving || !props.enabled) return
    setX(e.data.global.x)
    setY(e.data.global.y)
  }
  const spriteWidth = props.mobile ? getMobileWidth(props.form, props.stageWidth) : getWidth(props.form)
  const spriteHeight = props.mobile ? getMobileHeight(props.form) : getHeight(props.form)
  return useObserver(() => (
    <Container
      x={x}
      y={y}
      anchor={0.5}
      width={spriteWidth}
      height={spriteHeight}
      ref={fieldRef}
      name={`card_${props.card.name}`}
      interactive
      {
        ...props.mobile ? {
          touchstart: () => {
            console.log('Touch start')
            onTouchStart()
          },
          touchmove: onMove,
          touchend: (e) => {
            console.log('Touch end')
            onTouchEnd(e)
          },
        } : {
          click: onClick,
          mousemove: onMove,
        }
      }
    >
      <Sprite
        image="https://s3-us-west-2.amazonaws.com/s.cdpn.io/693612/coin.png"
        width={spriteWidth}
        height={spriteHeight}
        anchor={0.5}
        alpha={moving ? 0.6 : 1}
      />
      <Container
        anchor={1}
        visible={Boolean(props.color)}
      >
        <Graphics
          alpha={0.5}
          draw={g => {
            g.clear()
            const color = colorString.to.hex(colorString.get.rgb(props.color || 'red'))
            g.beginFill(Number(`0x${color.slice(1)}`))
            const width = spriteWidth
            const height = spriteHeight
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
            fill: [props.form === 'square' ? 'red' : 'grey'],
            stroke: 'white',
            strokeThickness: 3,
          })
        }
      />
    </Container>
  ))
}

export default Field
