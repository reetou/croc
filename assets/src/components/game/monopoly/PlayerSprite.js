import { Sprite, Container, Text, useTick, Graphics } from '@inlet/react-pixi'
import { useObserver } from 'mobx-react-lite'
import React, { useState, useEffect, useRef } from 'react'
import * as PIXI from 'pixi.js'
import { Ease } from 'pixi-ease'
import { toJS } from 'mobx'
import { maxBy, findIndex } from 'lodash-es'
import colorString from 'color-string'

function PlayerSprite(props) {
  const [moving, setMoving] = useState(false)
  const [x, setX] = useState(props.x || 0)
  const [y, setY] = useState(props.y || 0)
  const [oldX, setOldX] = useState(props.x || 0)
  const [oldY, setOldY] = useState(props.x || 0)
  const ref = useRef(null)
  const [oldPos, setPos] = useState(0)

  const goAnim = (i, easeList, ref, squares) => {
    const item = squares[i]
    if (i >= squares.length) {
      console.log('Last finished for', item)
      return
    }
    const newEase = new Ease({ duration: 1000 })
    if (i === 0) {
      easeList.add(ref.current, { x: item.point.x, y: item.point.y }, { duration: 500 })
      return goAnim(i + 1, easeList, ref, squares)
    } else {
      easeList.on('complete', () => {
        easeList.destroy()
        newEase.add(ref.current, { x: item.point.x, y: item.point.y }, { duration: 500 })
      })
    }
    return goAnim(i + 1, newEase, ref, squares)
  }

  useEffect(() => {
    if (props.position === null) return
    const old_position = props.old_position || 0
    if (old_position === props.position) return
    console.log(`Moving to ${props.position} from ${props.old_position}`)
    let squares = props.squares
      .filter(card => {
        if (props.position > old_position) {
          return (card.position > old_position && card.position < props.position)
        }
        return card.position > old_position || card.position < props.position
      })
      .map(s => ({ position: s.position, point: toJS(s.point) }))
      .sort((a, b, arr) => {
        if (props.position > old_position) {
          return a.position - b.position
        }
        if (b.position === 0) {
          return -9999
        }
        if (b.position > props.position) {
          const ind = b.position - props.position
          console.log(`Index for ${b.position}`, ind)
          return ind
        }
        console.log(`Index for ${b.position}`, b.position - a.position)
        return b.position - a.position
      })
    // Тут надо добавить какое то важное условие чтобы карта не скакала
    if (props.position < old_position) {
      const max = maxBy(squares, 'position')
      const zero = squares.find(s => s.position === 0)
      const index = findIndex(squares, s => s.position === max.position)
      if (index >= 0 && zero) {
        squares = squares.slice(0, squares.length - 1)
        console.log('Index', index)
        const z = squares.splice(index + 1, 0, zero)
        console.log('Returned z', z)
        console.log('Squares', squares)
      }
    }

    goAnim(0, new Ease({ duration: 1000 }), ref, squares.concat([{ point: { x: props.x, y: props.y } }]))
  }, [props.x, props.y])
  return useObserver(() => (
    <Container
      x={x}
      y={y}
      anchor={0.5}
      width={32}
      height={32}
      ref={ref}
      name={`player_${props.player_id}`}
    >
      <Sprite
        x={-8}
        anchor={0.5}
        y={-8}
        image={`https://cdn.discord-underlords.com/players/player${props.index}.png`}
        width={32}
        height={32}
        name={`player_sprite_${props.index}`}
      />
      <Text
        visible={props.enabled}
        x={0}
        y={0}
        anchor={0.5}
        text={props.position}
        style={
          new PIXI.TextStyle({
            fill: ['black', 'white', 'red', 'yellow'],
            stroke: 'white',
            strokeThickness: 3,
          })
        }
      />
    </Container>
  ))
}

export default PlayerSprite
