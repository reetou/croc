import React from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  ModalCard,
  ModalPage,
  ModalPageHeader,
  HeaderButton,
  ModalRoot,
  Div,
} from '@vkontakte/vkui'
import ErrorOutline56Icon from '@vkontakte/icons/dist/56/error_outline'
import DenyOutline56Icon from '@vkontakte/icons/dist/56/do_not_disturb_outline'
import Icon24Done from '@vkontakte/icons/dist/24/done'
import { usePlatform, IOS } from '@vkontakte/vkui'
import { toJS } from 'mobx'
import Brand from './cards_info/Brand'
import RandomEvent from './cards_info/RandomEvent'
import Start from './cards_info/Start'
import Payment from './cards_info/Payment'
import CardInDevelopment from './cards_info/CardInDevelopment'
import VkEventCardsForm from './VkEventCardsForm'

function getErrorMessage(errorMessage) {
  switch (errorMessage) {
    case 'already_in_lobby': return 'Вы уже находитесь в лобби'
    case 'authenticate_first': return 'Вход не был завершен полностью. Попробуйте перезапустить приложение'
    case 'lobby_timeout': return 'Истек срок ожидания начала игры. Лобби было закрыто.'
    case 'lobby_closed': return 'Ваше лобби было закрыто администратором.'
    case 'not_enough_players': return 'Недостаточно игроков для старта игры'
    case 'maximum_players': return 'Достигнуто максимальное количество игроков в лобби'
    default: return 'Неизвестная ошибка'
  }
}
const cardInfo = (card) => {
  switch (card.type) {
    case 'random_event': return <RandomEvent card={card} />
    case 'brand': return <Brand card={card} />
    case 'start': return <Start card={card} />
    case 'payment': return <Payment card={card} />
    case 'jail_cell':
    case 'teleport':
    case 'prison': return <CardInDevelopment card={card} />
    default: return null
  }
}

function Modals({ activeModal, onClose, onSignIn, onGetUserData, errorMessage, params }) {
  const platform = usePlatform()
  console.log('Params', toJS(params))
  const executeAndClose = async (fun) => {
    try {
      await fun()
      onClose()
    } catch (e) {
      console.error('Cannot execute', e)
      onClose()
    }
  }
  const state = useLocalStore(() => ({
    selectedCardsIds: []
  }))
  return useObserver(() => (
    <ModalRoot activeModal={activeModal}>
      <ModalCard
        id={'email_not_confirmed'}
        onClose={onClose}
        icon={<ErrorOutline56Icon />}
        title="Email не подтвержден"
        caption="Подтвердите Email в настройках профиля Вконтакте и попробуйте снова"
        actions={[{
          title: 'Сейчас сделаю',
          type: 'primary',
          action: onClose
        }]}
      />
      <ModalCard
        id={'cannot_get_email'}
        onClose={onClose}
        icon={<DenyOutline56Icon />}
        title="Не удалось получить Email"
        caption="Без вашего Email мы не можем допустить вас к игре.
          Пожалуйста, разрешите доступ к Email, чтобы продолжить."
        actions={[{
          title: 'Ладно',
          type: 'primary',
          action: onSignIn
        }]}
      />
      <ModalCard
        id={'cannot_get_user_data'}
        onClose={onClose}
        icon={<DenyOutline56Icon />}
        title="Не удалось получить данные профиля"
        caption="Без вашего имени игроки не смогут вас запомнить! Пожалуйста, разрешите доступ к данным профиля"
        actions={[{
          title: 'Ладно',
          type: 'primary',
          action: onGetUserData
        }]}
      />
      <ModalCard
        id={'lobby_error'}
        onClose={onClose}
        icon={<DenyOutline56Icon />}
        title="Не удалось присоединиться к лобби"
        caption={getErrorMessage(errorMessage)}
        actions={[{
          title: 'Понятно',
          type: 'primary',
          action: onClose
        }]}
      />
      <ModalCard
        id={'free_card_action'}
        onClose={onClose}
        icon={<DenyOutline56Icon />}
        title={params.title || 'Выберите, что делать с полем'}
        caption={'Вы можете купить поле или выставить его на аукцион'}
        actions={[
          {
            title: 'Купить',
            type: 'primary',
            action: () => executeAndClose(params.onBuy)
          },
          {
            title: 'На аукцион',
            type: 'primary',
            action: () => executeAndClose(params.onRejectBuy)
          },
        ]}
      />
      <ModalCard
        id={'auction_action'}
        onClose={onClose}
        icon={<DenyOutline56Icon />}
        title={params.title || 'Аукцион!'}
        caption={'Поднимите ставку или откажитесь от аукциона'}
        actions={[
          {
            title: 'Отказаться от участия в аукционе',
            type: 'primary',
            action: () => executeAndClose(params.onReject)
          },
          ...params.event ? [{
            title: `Поднять ставку до ${params.event.amount}`,
            type: 'primary',
            action: () => executeAndClose(params.onBid)
          }] : [],
        ]}
      />
      <ModalPage
        id={'field_actions'}
        onClose={onClose}
        settlingHeight={50}
        header={
          <ModalPageHeader
            right={(
              <HeaderButton
                onClick={() => {
                  onClose()
                }}
              >
                {platform === IOS ? 'Готово' : <Icon24Done />}
              </HeaderButton>
            )}
          >
            {params.title || 'Поле'}
          </ModalPageHeader>
        }
      >
        {
          params.card
            ? (
              <React.Fragment>
                <Div>
                  {cardInfo(params.card)}
                  {
                    params.isOwner
                      ? (
                        <Div>
                          Это ваше поле
                        </Div>
                      )
                      : (
                        <Div>
                          {!params.card.owner ? null : `Это поле занято ${params.card.owner}`}
                        </Div>
                      )
                  }
                </Div>
              </React.Fragment>
            )
            : (
              null
            )
        }
      </ModalPage>
      <ModalPage
        id={'edit_event_cards'}
        onClose={onClose}
        icon={<ErrorOutline56Icon />}
        header={
          <ModalPageHeader
            right={(
              <HeaderButton
                onClick={() => executeAndClose(async () => params.onSubmit(state.selectedCardsIds))}
              >
                {platform === IOS ? 'Сохранить' : <Icon24Done />}
              </HeaderButton>
            )}
          >
            Колода
          </ModalPageHeader>
        }
      >
        {
          params.user_monopoly_event_cards
            ? (
              <VkEventCardsForm
                {...params}
                onSelect={(cardsIds) => {
                  state.selectedCardsIds = cardsIds
                }}
                selectedCardsIds={state.selectedCardsIds}
              />
            )
            : null
        }
      </ModalPage>
    </ModalRoot>
  ))
}

export default Modals
