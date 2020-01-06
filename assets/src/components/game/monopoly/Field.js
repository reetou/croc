import { useApp, Sprite, Container, Text, Graphics } from '@inlet/react-pixi'
import { useObserver } from 'mobx-react-lite'
import React, { useState, useEffect, useRef } from 'react'
import * as PIXI from 'pixi.js'
import colorString from 'color-string'
import {
  getMobileWidth,
  getMobileHeight,
  getSpriteWidth,
  getSpriteHeight, getTagPoint,
} from '../../../util'


function Field(props) {
  const app = useApp()
  const [moving, setMoving] = useState(false)
  const [x, setX] = useState(props.x || 0)
  const [y, setY] = useState(props.y || 0)
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
  const spriteWidth = getSpriteWidth(props.form)
  const spriteHeight = getSpriteHeight(props.form)
  const getSpriteY = () => {
    switch (props.form) {
      case 'vertical': return 21
      default: return 0
    }
  }
  const getSpriteX = () => {
    switch (props.form) {
      case 'horizontal-flip': return 21
      default: return 0
    }
  }
  const spriteY = getSpriteY()
  const spriteX = getSpriteX()
  const width = getMobileWidth(props.form)
  const height = getMobileHeight(props.form)
  // console.log(`Sprite height for form ${props.form} ${getSpriteHeight(props.form)}`)
  // console.log(`Sprite width for form ${props.form} ${getSpriteWidth(props.form)} while container width ${getMobileWidth(props.form)}`)
  const imagePlaceholder = 'https://s3-us-west-2.amazonaws.com/s.cdpn.io/693612/coin.png'
  return useObserver(() => (
    <Container
      x={x}
      y={y}
      width={width}
      height={height}
      ref={fieldRef}
      name={`card_${props.card.name}`}
      interactive={props.interactive}
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
        x={spriteX}
        y={spriteY}
        image={process.env.NODE_ENV === 'production' ? props.card.image_url || imagePlaceholder : imagePlaceholder}
        width={spriteWidth}
        height={spriteHeight}
        alpha={moving ? 0.6 : 1}
      />
      <Container
        anchor={1}
        // visible={Boolean(props.color)}
        visible={true}
      >
        <Graphics
          visible={props.form !== 'square'}
          alpha={0.5}
          draw={g => {
            g.clear()
            const color = colorString.to.hex(colorString.get.rgb(props.color || 'red'))
            g.beginFill(Number(`0x${color.slice(1)}`))
            const vertical = props.form === 'vertical' || props.form === 'vertical-flip'
            const { x, y } = getTagPoint(props.form)
            const width = 49
            const height = 21
            g.drawRect(x, y, vertical ? width : height, vertical ? height : width)
            g.endFill()
          }}
        />
        <Graphics
          alpha={0.5}
          draw={g => {
            g.clear()
            const color = colorString.to.hex(colorString.get.rgb(props.color || 'red'))
            g.beginFill(Number(`0x${color.slice(1)}`))
            const width = spriteWidth
            const height = spriteHeight
            // g.drawRect(width / 2 * -1, height / 2 * -1, width, height)
            g.drawRect(spriteX, spriteY, width, height)
            g.endFill()
          }}
        />
      </Container>
      <Text
        visible={props.enabled}
        // visible={true}
        x={0}
        y={0}
        text={spriteY}
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
