import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Cell, Div, Group, InfoRow, List } from '@vkontakte/vkui'

function Prison({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
    >
      <Div>
        При попадании на поле вы будете отправлены в клетку, где будете отбывать срок, пока не выбросите дубль или не заплатите налог
      </Div>
    </Group>
  ))
}

export default Prison
