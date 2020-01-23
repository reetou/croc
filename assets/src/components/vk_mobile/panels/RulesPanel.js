import React from 'react'
import { useObserver } from 'mobx-react-lite'
import {
  HeaderButton,
  PanelHeader,
  PanelHeaderContent,
  Div, Group, Gallery,
} from '@vkontakte/vkui'

function RulesPanel(props) {
  return useObserver(() => (
    <React.Fragment>
      <PanelHeader
        left={<HeaderButton onClick={props.onGoBack}>Назад</HeaderButton>}
      >
        <PanelHeaderContent>
          Правила
        </PanelHeaderContent>
      </PanelHeader>
      <Group header={<Div>Поля-фирмы</Div>}>
        <Gallery
          slideWidth="custom"
          style={{ height: 120 }}
        >
          {
            [
              'https://cdn.discord-underlords.com/Footbalio.png',
              'https://cdn.discord-underlords.com/Pizzahot.png',
              'https://cdn.discord-underlords.com/UNIBANK.png',
              'https://cdn.discord-underlords.com/Sunresort.png'
            ].map(url => (
              <div style={{ width: 100 }} key={url}>
                <img src={url} style={{ width: 'inherit' }} />
              </div>
            ))
          }
        </Gallery>
        <Div>Попав на поле с фирмой, вы можете купить ее, если она никем не занята. Игроки, попадающие на чужую фирму, платят аренду владельцу фирмы.</Div>
        <Div>Продать поле без использования колоды карт нельзя.</Div>
        <Div>Собрав все карты одного типа, вы собираете монополию. Теперь вы сможете строить филиалы и налог при попадании на поле будет выше и выше.</Div>
        <Div>Поле можно заложить, чтобы получить дополнительные деньги. В этом случае при попадании на поле игроки ничего не платят. Также это поле может быть целью игроков, которые используют карты из колоды.</Div>
        <Div>Заложенное поле можно выкупить.</Div>
      </Group>
      <Group header={<Div>Особые поля</Div>}>
        <Gallery
          slideWidth="custom"
          style={{ height: 120 }}
        >
          {
            [
              'https://cdn.discord-underlords.com/Start.png',
              'https://cdn.discord-underlords.com/Prison.png',
              'https://cdn.discord-underlords.com/Portal.png',
              'https://cdn.discord-underlords.com/Police.png'
            ].map(url => (
              <div style={{ width: 100 }} key={url}>
                <img src={url} style={{ width: 'inherit' }} />
              </div>
            ))
          }
        </Gallery>
        <Div>Некоторые поля влияют на игрока, попавшего на поле, особым образом.</Div>
        <Div>Старт - поле, с которого начинают все при старте игры. При прохождении через поле Старт игрок получает $ 1000</Div>
        <Div>Тюрьма - при попадании на поле Тюрьма ничего не происходит :)</Div>
        <Div>Телепорт - переносит игрока на случайное поле.</Div>
        <Div>Полицейский участок - переносит игрока на поле Тюрьма. Игрок пропустит следующий раунд.</Div>
      </Group>
      <Group header={<Div>Другие поля</Div>}>
        <Div>Также в игре имеются поля Шанс и Налог.</Div>
        <Div>При попадании на поле Шанс, вы можете получить случайное событие - вам придется заплатить, вы можете получить деньги, а может случиться еще что-нибудь. Об этом вы узнаете в процессе игры.</Div>
        <Div>При попадании на поле Налог вы платите случайную сумму.</Div>
      </Group>
      <Group
        header={<Div>Колода карт</Div>}
        description="Мы планируем добавить больше карт и полей в будущем, чтобы разнообразить игру и компенсировать рандом при броске кубиков."
      >
        <Gallery
          slideWidth="custom"
          style={{ height: 120 }}
        >
          {
            [
              'https://cdn.discord-underlords.com/eventcards/force-auction.png',
              'https://cdn.discord-underlords.com/eventcards/force-sell-loan.png',
              'https://cdn.discord-underlords.com/eventcards/force-teleportation.png'
            ].map(url => (
              <div style={{ width: 100 }} key={url}>
                <img src={url} style={{ width: 'inherit' }} />
              </div>
            ))
          }
        </Gallery>
        <Div>После 10-го раунда вы можете использовать карты из колоды, которая состоит из карт всех игроков, собранных перед началом игры.</Div>
        <Div>У каждой карты своя цена, которая меняется в процессе игры.</Div>
        <Div>Карты - расходуемые предметы. Они могут быть получены во время игры или через магазин.</Div>
        <Div>Аукцион - выставляет выбранное поле на аукцион, если у поля есть владелец и оно находится не в монополии.</Div>
        <Div>Дефолт - продает все заложенные поля, не находящиеся в монополии. Остаток цены поля будет возвращен владельцам.</Div>
        <Div>Перенос - переносит всех игроков на выбранное поле. При переносе на старт или при его пересечении игроки не получают никаких дополнительных денег.</Div>
      </Group>
    </React.Fragment>
  ))
}

export default RulesPanel
