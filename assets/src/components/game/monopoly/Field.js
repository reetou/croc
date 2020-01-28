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
  const spriteWidth = getSpriteWidth(props.form)
  const spriteHeight = getSpriteHeight(props.form)
  const loadTextureOptions = {
    metadata: {
      choice: ['@1x.png', '@2x.png', '@3x.png']
    },
    scale: 0.5,
  }
  const textureOptions = {
    mipmap: PIXI.MIPMAP_MODES.OFF,
    resolution: PIXI.settings.RESOLUTION,
    width: spriteWidth,
    height: spriteHeight,
    scaleMode: PIXI.SCALE_MODES.LINEAR,
  }
  const [logoTexture, setLogoTexture] = useState(null)
  const fieldTextureImageUrl = 'https://cdn.discord-underlords.com/field-texture.png'
  const [backgroundTexture, setBackgroundTexture] = useState(PIXI.Texture.from(fieldTextureImageUrl, textureOptions))
  const createLoader = () => {
    const l = new PIXI.Loader()
    const extensions = PIXI.compressedTextures.detectExtensions(app.renderer)
    l.pre(PIXI.compressedTextures.extensionChooser(extensions))
    return l
  }
  const [loader, setLoader] = useState(createLoader())
  useEffect(() => {
    loader
      .add(props.card.name, props.card.image_url, loadTextureOptions)
      .add('field_texture', fieldTextureImageUrl, loadTextureOptions)
      .load((loader, resources) => {
        const resource = resources[props.card.name]
        resource.texture.baseTexture.scaleMode = PIXI.SCALE_MODES.LINEAR
        console.log(`Resource for ${props.card.name}`, resource)
        setLogoTexture(resource.texture)
        const backgroundResource = resources['field_texture']
        console.log(`Texture background for resource ${props.card.name}`, backgroundResource)
        setBackgroundTexture(backgroundResource.texture)
      })
  }, [])
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
        texture={backgroundTexture}
        x={spriteX}
        y={spriteY}
        width={spriteWidth}
        height={spriteHeight}
        name={`field_texture`}
      />
      {
        logoTexture
          ? (
            <Sprite
              x={spriteX}
              y={spriteY}
              texture={logoTexture}
              width={spriteWidth}
              height={spriteHeight}
              name={`sprite_width_${spriteWidth}_height_${spriteHeight}`}
              alpha={moving ? 0.6 : 1}
              scaleMode={PIXI.SCALE_MODES.LINEAR}
            />
          )
          : null
      }
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
            let colorStr = props.card.type === 'brand' ? ('#FFF') : '#333'
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
          resolution={PIXI.settings.RESOLUTION}
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
          resolution={PIXI.settings.RESOLUTION}
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
        resolution={PIXI.settings.RESOLUTION}
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
