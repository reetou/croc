import React from 'react'
import {
  HeaderButton,
  HorizontalScroll,
  IOS,
  ModalPage,
  Button,
  ModalPageHeader,
  Div,
  usePlatform
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
import VkEventCardThumb from '../VkEventCardThumb'

function DeckModal(props) {
  const platform = usePlatform()
  if (!props.params || !props.params.cards) return null
  const { params, onClose } = props
  const state = useLocalStore(() => ({
    type: null,
    get completedMonopolies() {
      const brandCards = params.cards.filter(c => c.type === 'brand')
      console.log('Groups', groupBy(brandCards, 'monopoly_type'))
      const groups = Object.values(groupBy(brandCards, 'monopoly_type'))
        .filter(group => {
          const card = group.find(c => c.owner)
          if (!card) return false
          return without(group.map(c => c.owner), card.owner).length === 0
        })
      console.log(`Groups with monopolies`, toJS(groups))
      return flatten(groups)
    },
    get positionsForCard() {
      switch (this.type) {
        case 'force_auction':
          const result = params.cards
            .filter(c => c.owner)
            .filter(c => c.type === 'brand')
            .filter(c =>
              !this.completedMonopolies
                .map(z => z.monopoly_type)
                .includes(c.monopoly_type)
            )
          return result
        case 'force_sell_loan':
          return params.cards.filter(c => c.on_loan && c.owner)
        case 'force_teleportation':
          return params.cards
        default: return []
      }
    }
  }))
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
          Выберите карту
        </ModalPageHeader>
      }
    >
      {
        state.type
          ? (
            <React.Fragment>
              <HorizontalScroll>
                {
                  state.positionsForCard.length
                    ? (
                      <div style={{ display: 'flex' }}>
                        {
                          state.positionsForCard.map((c) => (
                            <VkEventCardThumb
                              width={120}
                              onClick={async () => {
                                console.log(`Chosen card for deck action ${state.type}`, toJS(c))
                                const data = {
                                  type: state.type,
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
                              key={c.id}
                              src={c.image_url}
                            />
                          ))
                        }
                      </div>
                    )
                    : (
                      <Div>
                        Нет доступных карт для выбора
                        <Button onClick={() => state.type = null}>Назад</Button>
                      </Div>
                    )
                }
              </HorizontalScroll>
            </React.Fragment>
          )
          : (
            <React.Fragment>
              {
                params.event_cards
                  .map((c) => (
                    <VkEventCard
                      key={c.id}
                      buttonText="Выбрать"
                      onClick={() => {
                        console.log(`Choosing card ${c.id}`, toJS(c))
                        state.type = c.type
                      }}
                      name={c.name}
                      description={c.description}
                      src={c.image_url}
                    />
                  ))
              }
            </React.Fragment>
          )
      }
    </ModalPage>
  ))
}

export default DeckModal
