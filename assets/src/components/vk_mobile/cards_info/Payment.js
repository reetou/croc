import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Cell, Group, InfoRow, List } from '@vkontakte/vkui'

function Payment({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
      description="При попадании на поле вы платите в банк игры"
    >
      <List>
        <Cell>
          <InfoRow header="Сумма выплаты при попадании">
            {card.payment_amount}
          </InfoRow>
        </Cell>
      </List>
    </Group>
  ))
}

export default Payment
