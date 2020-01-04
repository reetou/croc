import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { Button, Cell, Div } from '@vkontakte/vkui'

function VkEventCard(props) {

  return useObserver(() => (
    <Cell
      description={props.description}
      multiline
      bottomContent={<Button mode={props.mode || 'primary'} onClick={props.onClick}>{props.buttonText}</Button>}
      before={(
        <Div>
          <img src={props.src} width="90" />
        </Div>
      )}
      size="l"
    >
      {props.name}
    </Cell>
  ))
}

export default VkEventCard
