import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Cell, Group, InfoRow, List } from '@vkontakte/vkui'

function Start({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
    >
      <List>
        <Cell>
          <InfoRow header="Доход при прохождении через поле">
            {2000}
          </InfoRow>
        </Cell>
        <Cell>
          <InfoRow
            header="Доп. доход при попадании на поле"
          >
            {1000}
          </InfoRow>
        </Cell>
      </List>
    </Group>
  ))
}

export default Start
