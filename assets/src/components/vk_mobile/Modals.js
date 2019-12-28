import React from 'react'
import { useObserver } from 'mobx-react-lite'
import { ModalCard, ModalRoot } from '@vkontakte/vkui'
import ErrorOutline56Icon from '@vkontakte/icons/dist/56/error_outline'
import DenyOutline56Icon from '@vkontakte/icons/dist/56/do_not_disturb_outline'

function Modals({ activeModal, onClose, onSignIn, onGetUserData }) {
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
    </ModalRoot>
  ))
}

export default Modals