import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Cell, Div, Group, InfoRow, List } from '@vkontakte/vkui'

function RandomEvent({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
    >
      <Div>
        Вызывает случайное событие на игрока, попавшего на это поле
      </Div>
    </Group>
  ))
}

export default RandomEvent
