import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Div,
  Panel,
  PanelHeader,
  ScreenSpinner,
  View,
  Button,
  Group,
} from '@vkontakte/vkui'
import axios from '../../../axios'
import VkEventCard from '../VkEventCard'
import { toJS } from 'mobx'
import connect from '@vkontakte/vk-connect'

function ShopView(props) {
  const state = useLocalStore((source) => ({
    activePanel: 'main',
    event_cards: [],
    small_pack_amount: 0,
    large_pack_amount: 0,
    popout: <ScreenSpinner/>,
  }), props)
  const getProducts = async () => {
    try {
      if (!state.popout) {
        state.popout = <ScreenSpinner/>
      }
      console.log('Getting')
      const res = await axios({
        url: '/shop',
        method: 'GET',
        headers: {
          Authorization: `Bearer ${props.user.access_token}`
        }
      })
      state.event_cards = res.data.products.event_cards
      state.small_pack_amount = res.data.small_pack_amount
      state.large_pack_amount = res.data.large_pack_amount
    } catch (e) {
      console.error('Cannot get products', e)
      state.activePanel = 'loading_error'
    }
    state.popout = null
  }
  const onBuy = async (c) => {
    try {
      const res = await axios({
        url: '/shop/orders/create',
        method: 'POST',
        headers: {
          Authorization: `Bearer ${props.user.access_token}`
        },
        data: {
          product_type: 'small_pack'
        }
      })
      console.log('Data for signing is', res.data)
      const result = await connect.sendPromise('VKWebAppOpenPayForm', res.data)
      console.log('Result', result)
    } catch (e) {
      console.log('Error at buy', e)
    }
  }
  useEffect(() => {
    if (!props.user) {
      state.activePanel = 'loading_error'
      return
    }
    getProducts()
  }, [])
  const createShopWallPost = async () => {
    try {
      await connect.send("VKWebAppShowWallPostBox", {
        message: 'Подкиньте мне денег, чтобы я купил себе эти красивые карты в монополии',
        attachments: `photo536736851_457239040,photo536736851_457239039,photo536736851_457239038,https://vk.com/app7262387`
      });
    } catch (e) {
      console.error('Cannot create shop wall post', e)
    }
  }
  return useObserver(() => (
    <View
      id={props.id}
      activePanel={state.activePanel}
      popout={state.popout}
    >
      <Panel id={'main'}>
        <PanelHeader>Купить</PanelHeader>
        <Div>
          При пожертвовании {state.small_pack_amount} рублей и более вы получаете все эти карточки:
        </Div>
        <Group
          description="Дайте друзьям знать, чего вам не хватает. Вдруг кто-то поможет?"
        >
          <Div>
            <Button onClick={createShopWallPost}>Попросить у друзей</Button>
          </Div>
        </Group>
        {
          state.event_cards.map(c => (
            <VkEventCard
              key={c.id}
              name={c.name}
              description={c.description}
              src={c.image_url}
              mode="commerce"
              buttonText={`Купить`}
              onClick={() => {
                console.log(`Gonna buy ${c.name}`, toJS(c))
                onBuy(c)
              }}
            />
          ))
        }
      </Panel>
      <Panel id={'loading_error'}>
        <PanelHeader>Ошибка</PanelHeader>
        <Div>Не удалось загрузить список доступных товаров.</Div>
        <Div>
          <Button onClick={getProducts}>Попробовать снова</Button>
        </Div>
      </Panel>
    </View>
  ))
}

export default ShopView
