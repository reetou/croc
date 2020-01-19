import { useApp, Sprite, Container, Text, Graphics } from '@inlet/react-pixi'
import { useObserver } from 'mobx-react-lite'
import React, { useState, useEffect, useRef } from 'react'
import * as PIXI from 'pixi.js'
import colorString from 'color-string'
import {
  getMobileWidth,
  getMobileHeight,
  getSpriteWidth,
  getSpriteHeight,
  getTagPoint,
  getAngle,
  getUpgradeTagPoint,
  getUpgradeLevelText,
  getUpgradeLevelTextPosition,
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
  const angle = getAngle(props.form)
  // console.log(`Sprite height for form ${props.form} ${getSpriteHeight(props.form)}`)
  // console.log(`Sprite width for form ${props.form} ${getSpriteWidth(props.form)} while container width ${getMobileWidth(props.form)}`)
  const imagePlaceholder = 'https://s3-us-west-2.amazonaws.com/s.cdpn.io/693612/coin.png'
  const tagPoint = getTagPoint(props.form)
  const upgradeTagPoint = getUpgradeTagPoint(props.form)
  const upgradeTagTextPoint = getUpgradeLevelTextPosition(props.card.upgrade_level || 1)
  return useObserver(() => (
    <Container
      x={x}
      y={y}
      angle={angle}
      // width={width}
      // height={height}
      ref={fieldRef}
      name={`card_${props.card.name}_height_${height}`}
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
      <Container
        visible={Boolean(props.color)}
        name="white_background_for_owner_color"
      >
        <Graphics
          preventRedraw
          draw={g => {
            g.clear()
            g.beginFill(0xffffff)
            const width = spriteWidth
            const height = spriteHeight
            g.drawRoundedRect(spriteX, spriteY, width, height, 3)
            g.endFill()
          }}
        />
      </Container>
      <Container name="color_covering">
        <Graphics
          name={`covering_${props.color}`}
          draw={g => {
            g.clear()
            const color = colorString.to.hex(colorString.get.rgb(props.color || '#EADEC2'))
            g.beginFill(Number(`0x${color.slice(1)}`), props.color ? 0.3 : 1)
            const width = spriteWidth
            const height = spriteHeight
            // g.drawRect(width / 2 * -1, height / 2 * -1, width, height)
            g.drawRoundedRect(spriteX, spriteY, width, height, 1)
            g.endFill()
          }}
        />
      </Container>
      <Sprite
        image="https://cdn.discord-underlords.com/field-texture.png"
        x={spriteX}
        y={spriteY}
        width={spriteWidth}
        height={spriteHeight}
        name={`field_texture`}
      />
      <Sprite
        x={spriteX}
        y={spriteY}
        image={props.card.image_url || imagePlaceholder}
        width={spriteWidth}
        height={spriteHeight}
        name={`sprite_width_${spriteWidth}_height_${spriteHeight}`}
        alpha={moving ? 0.6 : 1}
      />
      <Container
        x={tagPoint.x}
        y={tagPoint.y}
        angle={tagPoint.angle || 0}
        name="price_tag"
      >
        <Graphics
          visible={props.form !== 'square'}
          draw={g => {
            g.clear()
            let colorStr = props.card.type === 'brand' ? ('#FFF') : '#4F4F4F'
            if (props.card.type === 'brand' && props.card.on_loan) {
              colorStr = '#F2C94C'
            }
            const color = colorString.to.hex(colorString.get.rgb(colorStr))
            g.beginFill(Number(`0x${color.slice(1)}`))
            const width = 49
            const height = 21
            g.drawRect(0, 0, width, height)
            g.endFill()
          }}
        />
        <Text
          x={5}
          y={4}
          visible={props.card.type === 'brand'}
          // visible={false}
          text={`$ ${props.card.payment_amount}`}
          style={
            new PIXI.TextStyle({
              fontSize: 12,
              fill: '#4F4F4F'
            })
          }
        />
      </Container>
      <Container
        visible={props.card.type === 'brand' && props.card.upgrade_level}
        x={upgradeTagPoint.x}
        y={upgradeTagPoint.y}
        angle={upgradeTagPoint.angle || 0}
        name="upgrade_level_tag"
      >
        <Sprite
          width={21}
          height={21}
          image="https://cdn.discord-underlords.com/upgrade-level-bg.png"
        />
        <Text
          x={upgradeTagTextPoint.x}
          y={upgradeTagTextPoint.y}
          text={getUpgradeLevelText(props.card.upgrade_level || 1)}
          style={
            new PIXI.TextStyle({
              fill: 'white',
              fontSize: 11,
            })
          }
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
