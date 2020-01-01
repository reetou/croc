import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Div, Group } from '@vkontakte/vkui'

function CardInDevelopment({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
    >
      <Div>
        Механика поля в разработке, скоро сделаем!
      </Div>
    </Group>
  ))
}

export default CardInDevelopment
