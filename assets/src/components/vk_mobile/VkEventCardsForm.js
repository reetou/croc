import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Cell,
  Gallery,
  Group,
  List,
} from '@vkontakte/vkui'
import VkEventCard from './VkEventCard'
import VkEventCardThumb from './VkEventCardThumb'

function VkEventCardsForm(props) {
  const state = useLocalStore(() => ({
    selectedCardsIds: props.selectedCardsIds || [],
    eventCards: props.user_monopoly_event_cards || [],
    get selectedEventCards() {
      return this.eventCards.filter(c => this.selectedCardsIds.includes(c.id))
    },
    get availableEventCards() {
      return this.eventCards.filter(c => !this.selectedCardsIds.includes(c.id))
    }
  }))
  useEffect(() => {
    if (props.selected_event_cards && props.selected_event_cards.length) {
      const alreadySelectedIds = props.selected_event_cards.map(c => c.id)
      state.selectedCardsIds = alreadySelectedIds
      props.onSelect(alreadySelectedIds)
    }
  }, [])
  return useObserver(() => (
    <React.Fragment>
      <Group
        header={state.selectedCardsIds.length ? "Нажмите на карту, чтобы удалить" : "Выберите карты"}
        description="Вы можете купить карты в магазине"
      >
        {
          state.selectedCardsIds.length
            ? (
              <Gallery
                slideWidth="custom"
                style={{ height: 120 }}
              >
                {
                  state.selectedEventCards.map(({ monopoly_event_card: c, id }) => (
                    <VkEventCardThumb
                      key={id}
                      src={c.image_url}
                      onClick={() => {
                        state.selectedCardsIds = state.selectedCardsIds.filter(sid => sid !== id)
                        props.onSelect(state.selectedCardsIds)
                      }}
                    />
                  ))
                }
              </Gallery>
            )
            : null
        }
        <List>
          {
            state.availableEventCards.length === 0
              ? (
                <Cell
                  multiline
                  size="l"
                >
                  У вас нет карт. Вы можете купить их в магазине.
                </Cell>
              )
              : null
          }
          {
            state.availableEventCards.map(({ monopoly_event_card: c, id }) => (
              <VkEventCard
                key={id}
                name={c.name}
                description={c.description}
                src={c.image_url}
                buttonText="Добавить"
                onClick={() => {
                  state.selectedCardsIds.push(id)
                  props.onSelect(state.selectedCardsIds)
                }}
              />
            ))
          }
        </List>
      </Group>
    </React.Fragment>
  ))
}

export default VkEventCardsForm
