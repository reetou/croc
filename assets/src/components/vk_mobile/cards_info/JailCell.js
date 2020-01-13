import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Cell, Div, Group, InfoRow, List } from '@vkontakte/vkui'

function JailCell({ card }) {
  return useObserver(() => (
    <Group
      header="Информация о поле"
    >
      <Div>
        Клетка - поле, в которое вы попадете, наступив на полицейский участок.
        Если вы попадаете сюда не через полицейский участок, можете быть спокойны.
      </Div>
    </Group>
  ))
}

export default JailCell
