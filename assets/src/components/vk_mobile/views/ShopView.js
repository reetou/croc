import React, { useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Div,
  Panel,
  PanelHeader,
  ScreenSpinner,
  View,
  Button,
} from '@vkontakte/vkui'
import axios from '../../../axios'
import VkEventCard from '../VkEventCard'
import { toJS } from 'mobx'
import connect from '@vkontakte/vk-connect'

function ShopView(props) {
  const state = useLocalStore((source) => ({
    activePanel: 'main',
    event_cards: [],
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
      state.event_cards = res.data.event_cards
    } catch (e) {
      console.error('Cannot get products', e)
      state.activePanel = 'loading_error'
    }
    state.popout = null
  }
  const onBuy = async ({ id }) => {
    try {
      const res = await axios({
        url: '/shop/orders/create',
        method: 'POST',
        headers: {
          Authorization: `Bearer ${props.user.access_token}`
        },
        data: {
          product_id: id,
          product_type: 'event_card'
        }
      })
      console.log('Data for signing is', res.data)
      await connect.sendPromise('VKWebAppOpenPayForm', res.data)
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
  return useObserver(() => (
    <View
      id={props.id}
      activePanel={state.activePanel}
      popout={state.popout}
    >
      <Panel id={'main'}>
        <PanelHeader>Купить</PanelHeader>
        {
          state.event_cards.map(c => (
            <VkEventCard
              key={c.id}
              name={c.name}
              description={c.description}
              src={c.image_url}
              mode="commerce"
              buttonText={`Купить за ${c.price} р.`}
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
