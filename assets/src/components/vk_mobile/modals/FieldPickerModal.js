import React from 'react'
import {
  HeaderButton,
  IOS,
  ModalPage,
  Button,
  Group,
  ModalPageHeader,
  Div,
  List,
  usePlatform,
  Cell
} from '@vkontakte/vkui'
import Icon24Cancel from '@vkontakte/icons/dist/24/cancel'
import { useObserver } from 'mobx-react-lite'

function FieldPickerModal(props) {
  const platform = usePlatform()
  if (!props.params || !props.params.cards || !props.params.type) return null
  const { params, onClose } = props
  const { cards, type } = params
  return useObserver(() => (
    <ModalPage
      id={props.id}
      onClose={onClose}
      header={
        <ModalPageHeader
          right={(
            <HeaderButton
              onClick={onClose}
            >
              {platform === IOS ? 'Закрыть' : <Icon24Cancel />}
            </HeaderButton>
          )}
        >
          Выберите поле
        </ModalPageHeader>
      }
    >
      <Group>
        <List style={{ minHeight: 90 }}>
          {
            cards.map(c => (
              <Cell
                bottomContent={(
                  <React.Fragment>
                    <div>Доход при залоге: {c.loan_amount || 'Нет'}</div>
                    <div>Цена выкупа: {c.buyout_cost || 'Нет'}</div>
                    <div>Цена филиала: {c.upgrade_cost || 'Нет'}</div>
                    <Button
                      mode="primary"
                      onClick={async () => {
                        const data = {
                          type,
                          position: c.position,
                        }
                        props.setActiveModal(null, '')
                        try {
                          await params.onSubmit(data)
                        } catch (e) {
                          console.log('Error happened', e)
                          setTimeout(() => {
                            props.setActiveModal('lobby_error', 'Some shit happened')
                          }, 0)
                        }
                      }}
                    >
                      Выбрать
                    </Button>
                  </React.Fragment>
                )}
                before={(
                  <Div>
                    <img src={c.image_url} width="90" />
                  </Div>
                )}
                size="l"
              >
                {c.name}
              </Cell>
            ))
          }
        </List>
      </Group>
    </ModalPage>
  ))
}

export default FieldPickerModal
