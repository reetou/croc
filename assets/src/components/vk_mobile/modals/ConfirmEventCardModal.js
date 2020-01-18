import React from 'react'
import {
  ModalCard,
} from '@vkontakte/vkui'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import { getEventCardCost } from '../../../util'

function ConfirmEventCardModal(props) {
  if (!props.params || !props.params.game || !props.params.event_card || !props.params.type) {
    console.error('Returning null because no required props in confirm event modal', props.params)
    return null
  }
  const { params, onClose, executeAndClose } = props
  const { event_card, game, type } = params
  const state = useLocalStore((source) => ({
    game: source.params.game,
    get cost() {
      return getEventCardCost(type, this.game)
    }
  }), props)
  return useObserver(() => (
    <ModalCard
      id={props.id}
      onClose={onClose}
      icon={<img width={90} src={event_card.image_url} />}
      title={'Подтвердите действие'}
      caption={`Вы платите ${state.cost} и используете карту ${event_card.name}`}
      actions={[
        {
          title: 'Принять',
          type: 'primary',
          action: () => executeAndClose(params.onSubmit)
        },
        {
          title: `Отмена`,
          type: 'primary',
          action: props.onClose
        }
      ]}
    />
  ))
}

export default ConfirmEventCardModal
