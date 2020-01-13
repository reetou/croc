import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Div, Group } from '@vkontakte/vkui'

function Prison({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
    >
      <Div>
        При попадании на поле вы будете отправлены в клетку, где будете отбывать срок в 1 раунд. Также вы не получите деньги за прохождение через старт.
      </Div>
    </Group>
  ))
}

export default Prison
