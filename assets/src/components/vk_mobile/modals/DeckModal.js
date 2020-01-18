import React from 'react'
import {
  HeaderButton,
  HorizontalScroll,
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
import {
  groupBy,
  without,
  flatten,
} from 'lodash-es'
import VkEventCard from '../VkEventCard'
import { toJS } from 'mobx'
import Icon24Cancel from '@vkontakte/icons/dist/24/cancel'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import { getCompletedMonopolies, getPositionsForEventCard } from '../../../util'

function DeckModal(props) {
  const platform = usePlatform()
  if (!props.params || !props.params.cards || !props.params.type) return null
  const { params, onClose } = props
  const { type } = params
  const state = useLocalStore(() => ({
    get completedMonopolies() {
      return getCompletedMonopolies(params.cards)
    },
    get positionsForCard() {
      return getPositionsForEventCard(type, params.cards, this.completedMonopolies)
    }
  }))
  const noAvailableFields = state.positionsForCard.length === 0
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
          {noAvailableFields ? 'Нельзя использовать карту' : 'Выберите поле'}
        </ModalPageHeader>
      }
    >
      <Group>
        <List style={{ minHeight: 90 }}>
          {
            state.positionsForCard.length === 0
              ? (
                <Cell
                  multiline
                >
                  Нет доступных полей для выбора. Видимо, время этой карты еще не пришло.
                </Cell>
              )
              : null
          }
          {
            state.positionsForCard.map((c) => (
              <Cell
                multiline
                bottomContent={(
                  <Button
                    mode="primary"
                    onClick={async () => {
                      const data = {
                        type,
                        position: c.position,
                      }
                      try {
                        onClose()
                        await params.onSubmit(data)
                      } catch (e) {
                        console.error('Error happened', e)
                        setTimeout(() => {
                          props.setActiveModal('lobby_error', 'Some shit happened')
                        }, 0)
                      }
                    }}
                  >
                    Выбрать
                  </Button>
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

export default DeckModal
