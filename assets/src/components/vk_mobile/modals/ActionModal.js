import React from 'react'
import { useObserver } from 'mobx-react-lite'
import {
  Button,
  Cell,
  Div,
  Group,
  PanelHeaderButton,
  IOS,
  List,
  ModalPage,
  ModalPageHeader, usePlatform
} from '@vkontakte/vkui'
import Icon24Cancel from '@vkontakte/icons/dist/24/cancel'


function ActionModal(props) {
  if (!props.params) return null
  const { params, onClose } = props
  if (!params.actions) return null
  const platform = usePlatform()
  return useObserver(() => (
    <ModalPage
      id={props.id}
      onClose={onClose}
      header={
        <ModalPageHeader
          right={(
            <PanelHeaderButton
              onClick={onClose}
            >
              {platform === IOS ? 'Закрыть' : <Icon24Cancel />}
            </PanelHeaderButton>
          )}
        >
          {params.title}
        </ModalPageHeader>
      }
    >
      <Group header={<Div>Выберите действие</Div>}>
        {
          params.card
            ? (
              <Cell
                before={<img src={params.card.image_url} width={100} />}
                description={params.card.name}
              >
                Цена: $ {params.cost}
              </Cell>
            )
            : null
        }
        {
          params.actions.map(a => (
            <Cell>
              <Button
                stretched
                onClick={async () => {
                  try {

                    await a.onClick()
                    onClose()
                  } catch (e) {
                    console.log('Error', e)
                  }
                }}
              >
                {a.text}
              </Button>
            </Cell>
          ))
        }
      </Group>
    </ModalPage>
  ))
}

export default ActionModal
