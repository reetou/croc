import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Cell, Div, Group, InfoRow, List } from '@vkontakte/vkui'

function JailCell({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
    >
      <Div>
        Клетка - поле, в которое вы попадете, наступив на тюрьму.
        Отсюда можно будет выйти, выбросив дубль или заплатив налог
      </Div>
      <List>
        <Cell>
          <InfoRow header="Сумма налога">
            {card.payment_amount}
          </InfoRow>
        </Cell>
      </List>
    </Group>
  ))
}

export default JailCell
