import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Cell, Div, Group, InfoRow, List } from '@vkontakte/vkui'

function Brand({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
      description={!card.owner ? 'Поле никем не занято. Чтобы его купить, нужно попасть на поле и иметь деньги для покупки' : null}
    >
      <Div>
        Если у поля есть владелец и оно не заложено, вы будете платить налог за попадание каждый раз, когда наступаете на поле.
        Если владелец соберет все поля из одной категории, он сможет строить филиалы и налог будет повышаться.
      </Div>
      <List>
        <Cell>
          <InfoRow header="Категория">
            {card.monopoly_type}
          </InfoRow>
        </Cell>
        <Cell>
          <InfoRow header="Налог за попадание">
            {card.owner && !card.on_loan ? card.payment_amount : 0}
          </InfoRow>
        </Cell>
        <Cell>
          <InfoRow header="Цена">
            {card.cost}
          </InfoRow>
        </Cell>
        <Cell>
          <InfoRow header="Постройка филиала">
            {card.upgrade_cost}
          </InfoRow>
        </Cell>
        <Cell>
          <InfoRow header="Доход при сдаче в залог">
            {card.loan_amount}
          </InfoRow>
        </Cell>
        <Cell>
          <InfoRow header="Цена выкупа">
            {card.buyout_cost}
          </InfoRow>
        </Cell>
      </List>
    </Group>
  ))
}

export default Brand
