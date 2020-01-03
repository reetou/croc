import React, { useEffect, lazy, Suspense } from 'react'
import { PhoenixSocketProvider } from './SocketContext'
import connect from '@vkontakte/vk-connect'
import {
  PanelHeader,
  View,
  Panel,
  Epic,
  Div,
  PanelSpinner,
  ScreenSpinner,
  Snackbar,
} from '@vkontakte/vkui'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import '@vkontakte/vkui/dist/vkui.css';
import axios from './axios'
import { at } from 'lodash-es'
import SnackbarContainer from './components/vk_mobile/SnackbarContainer'
import ProfileView from './components/vk_mobile/views/ProfileView'

const Modals = lazy(() => import('./components/vk_mobile/Modals'))
const GameView = lazy(() => import('./components/vk_mobile/views/GameView'))
const AppTabbar = lazy(() => import('./components/vk_mobile/AppTabbar'))
const LobbyView = lazy(() => import('./components/vk_mobile/views/LobbyView'))

let mock_game = {
  "cards": [
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 126,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": null,
      "name": "Start location",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 0,
      "raw_payment_amount": 1000,
      "type": "start",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 127,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "perfume",
      "name": "Dior",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 1,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": null,
      "cost": null,
      "id": 128,
      "loan_amount": null,
      "max_upgrade_level": null,
      "monopoly_type": null,
      "name": "Random event",
      "on_loan": null,
      "owner": null,
      "payment_amount": null,
      "position": 2,
      "raw_payment_amount": null,
      "type": "random_event",
      "upgrade_cost": null,
      "upgrade_level": 0,
      "upgrade_level_multipliers": null
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 129,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "perfume",
      "name": "Givenchy",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 3,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": null,
      "cost": null,
      "id": 130,
      "loan_amount": null,
      "max_upgrade_level": null,
      "monopoly_type": null,
      "name": "Payment",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 4,
      "raw_payment_amount": 1000,
      "type": "payment",
      "upgrade_cost": null,
      "upgrade_level": 0,
      "upgrade_level_multipliers": null
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 131,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "cars",
      "name": "Land Rover",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 5,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 132,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "clothing",
      "name": "ZARA",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 6,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": null,
      "cost": null,
      "id": 133,
      "loan_amount": null,
      "max_upgrade_level": null,
      "monopoly_type": null,
      "name": "Random event",
      "on_loan": null,
      "owner": null,
      "payment_amount": null,
      "position": 7,
      "raw_payment_amount": null,
      "type": "random_event",
      "upgrade_cost": null,
      "upgrade_level": 0,
      "upgrade_level_multipliers": null
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 134,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "clothing",
      "name": "Bershka",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 8,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 135,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "clothing",
      "name": "Reserved",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 9,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 136,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": null,
      "name": "Jail Cell",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 10,
      "raw_payment_amount": 1000,
      "type": "jail_cell",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 137,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "social_networks",
      "name": "Vkontakte",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 11,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 138,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "games",
      "name": "Kodjima Production",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 12,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 139,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "social_networks",
      "name": "Facebook",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 13,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 140,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "social_networks",
      "name": "Telegram",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 14,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 141,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "cars",
      "name": "Mazda",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 15,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 142,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "drinks",
      "name": "Coca Cola",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 16,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": null,
      "cost": null,
      "id": 143,
      "loan_amount": null,
      "max_upgrade_level": null,
      "monopoly_type": null,
      "name": "Random event",
      "on_loan": null,
      "owner": null,
      "payment_amount": null,
      "position": 17,
      "raw_payment_amount": null,
      "type": "random_event",
      "upgrade_cost": null,
      "upgrade_level": 0,
      "upgrade_level_multipliers": null
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 144,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "drinks",
      "name": "Fanta",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 18,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 145,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "drinks",
      "name": "Sprite",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 19,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 146,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": null,
      "name": "Teleport",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 20,
      "raw_payment_amount": 1000,
      "type": "teleport",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 147,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "airports",
      "name": "Lufthansa",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 21,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": null,
      "cost": null,
      "id": 148,
      "loan_amount": null,
      "max_upgrade_level": null,
      "monopoly_type": null,
      "name": "Random event",
      "on_loan": null,
      "owner": null,
      "payment_amount": null,
      "position": 22,
      "raw_payment_amount": null,
      "type": "random_event",
      "upgrade_cost": null,
      "upgrade_level": 0,
      "upgrade_level_multipliers": null
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 149,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "airports",
      "name": "Aeroflot",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 23,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 150,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "airports",
      "name": "S7 Airlines",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 24,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 151,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "cars",
      "name": "Tesla",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 25,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 152,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "fastfood",
      "name": "MacDonalds",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 26,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 153,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "fastfood",
      "name": "KFC",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 27,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 154,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "games",
      "name": "KONAMI",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 28,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 155,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "fastfood",
      "name": "Burger King",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 29,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 156,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": null,
      "name": "Prison",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 30,
      "raw_payment_amount": 1000,
      "type": "prison",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 157,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "hotels",
      "name": "Hyatt",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 31,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 158,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "hotels",
      "name": "Hilton",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 32,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": null,
      "cost": null,
      "id": 159,
      "loan_amount": null,
      "max_upgrade_level": null,
      "monopoly_type": null,
      "name": "Random event",
      "on_loan": null,
      "owner": null,
      "payment_amount": null,
      "position": 33,
      "raw_payment_amount": null,
      "type": "random_event",
      "upgrade_cost": null,
      "upgrade_level": 0,
      "upgrade_level_multipliers": null
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 160,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "hotels",
      "name": "Novotel",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 34,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 161,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "cars",
      "name": "Ford",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 35,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": null,
      "cost": null,
      "id": 162,
      "loan_amount": null,
      "max_upgrade_level": null,
      "monopoly_type": null,
      "name": "Debt",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 36,
      "raw_payment_amount": 1000,
      "type": "payment",
      "upgrade_cost": null,
      "upgrade_level": 0,
      "upgrade_level_multipliers": null
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 163,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "phones",
      "name": "Apple",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 37,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    },
    {
      "buyout_cost": null,
      "cost": null,
      "id": 165,
      "loan_amount": null,
      "max_upgrade_level": null,
      "monopoly_type": null,
      "name": "Random event",
      "on_loan": null,
      "owner": null,
      "payment_amount": null,
      "position": 38,
      "raw_payment_amount": null,
      "type": "random_event",
      "upgrade_cost": null,
      "upgrade_level": 0,
      "upgrade_level_multipliers": null
    },
    {
      "buyout_cost": 1200,
      "cost": 1500,
      "id": 166,
      "loan_amount": 1000,
      "max_upgrade_level": 2,
      "monopoly_type": "phones",
      "name": "Xiaomi",
      "on_loan": null,
      "owner": null,
      "payment_amount": 1000,
      "position": 39,
      "raw_payment_amount": 1000,
      "type": "brand",
      "upgrade_cost": 1200,
      "upgrade_level": 0,
      "upgrade_level_multipliers": [
        1.5,
        1.2
      ]
    }
  ],
  "ended_at": null,
  "event_cards": [
    {
      description: "Desc",
      id: 1,
      image_url: "https://croc-images.fra1.digitaloceanspaces.com/card_placeholder_vertical.png",
      name: "Аукционка",
      rarity: 1,
      type: "force_auction",
    },
    {
      description: "Desc",
      id: 2,
      image_url: "https://croc-images.fra1.digitaloceanspaces.com/card_placeholder_vertical.png",
      name: "Селл лоан",
      rarity: 1,
      type: "force_sell_loan",
    },
    {
      description: "Desc",
      id: 3,
      image_url: "https://croc-images.fra1.digitaloceanspaces.com/card_placeholder_vertical.png",
      name: "Принудительная телепортация",
      rarity: 1,
      type: "force_teleportation",
    },
  ],
  "props.game_id": "59979686-8ae0-4e41-a4e9-72b94b4c5259",
  "on_timeout": null,
  "player_turn": 66,
  "players": [
    {
      "__meta__": "Elixir.Memento.Table",
      "balance": 10000,
      "color": "red",
      "events": [
        {
          "amount": null,
          "event_id": "2de6a2c5-2a5f-4e14-b682-0c59d0f180de",
          "last_bidder": null,
          "members": [],
          "position": null,
          "priority": 100,
          "receiver": null,
          "starter": null,
          "text": "Ходит",
          "type": "roll"
        }
      ],
      "props.game_id": "59979686-8ae0-4e41-a4e9-72b94b4c5259",
      "id": null,
      "player_cards": [],
      "player_id": 66,
      "position": 0,
      "surrender": false
    }
  ],
  "round": 1,
  "started_at": "2019-12-24T00:18:08Z",
  "turn_timeout_at": null,
  "winners": []
}
mock_game = {
  ...mock_game,
  cards: mock_game.cards.map(c => ({
    ...c,
    image_url: 'https://croc-images.fra1.digitaloceanspaces.com/card_horizontal.png',
  }))
}

function VkMiniApp(props) {
  console.log('props at vk', props)
  const mock = {
    email: null,
    first_name: "Вова",
    id: 20,
    image_url: "https://sun9-71.userapi.com/c855132/v855132776/a7dc/AuDfdnWSglE.jpg?ava=1",
    photo_200: "https://sun9-71.userapi.com/c855132/v855132776/a7dc/AuDfdnWSglE.jpg?ava=1",
    last_name: "Синицынъ",
    user_monopoly_cards: [],
    username: null,
  }
  const state = useLocalStore(() => ({
    history: [],
    // activeStory: 'current_game',
    activeStory: 'find_game',
    profilePanel: 'main',
    activeModal: null,
    errorMessage: null,
    game: null,
    endedGame: null,
    gamePanel: null,
    messages: [],
    token: null,
    snackbar: null,
    modalParams: {},
    loading: false,
    banned: false,
    ban_id: null,
    user: process.env.NODE_ENV === 'production' ? null : mock,
    // user: null,
  }))
  const setActiveModal = (modal_id, errorMessage = null) => {
    state.activeModal = modal_id
    state.errorMessage = errorMessage
  }
  useEffect(() => {
    const handler = (e) => {
      console.log('Received VK event', e)
    }
    connect.subscribe(handler)
    connect.send('VKWebAppInit')
    getUserData()
    return () => {
      console.log('Unsubscribing')
      connect.unsubscribe(handler)
    }
  }, [])
  const onBan = (ban_id) => {
    if (ban_id) {
      state.ban_id = ban_id
    }
    state.banned = true
    state.profilePanel = 'banned'
    state.activeStory = 'profile'
  }
  const getUserData = async () => {
    if (process.env.NODE_ENV === 'production') {
      state.loading = true
    }
    try {
      if (process.env.NODE_ENV !== 'production') {
        state.token = 'SFMyNTY.g3QAAAACZAAEZGF0YWEUZAAGc2lnbmVkbgYAwavJSW8B.35xr0ff0rqzV5gNKuFZ8MEv70WLYH5SnyGXb2gXdkp0'
      }
      const userData = await connect.sendPromise('VKWebAppGetUserInfo')
      console.log('User data', userData)
      const res = await axios.post('/auth/vk', userData)
      state.user = res.data.user
      state.user.access_token = res.data.access_token
      state.token = res.data.token
    } catch (e) {
      console.log('User error', e)
      if (at(e, 'response.data.error')[0] === 'banned') {
        console.log('User was banned')
        onBan(e.response.data.ban_id)
      } else {
        state.activeModal = 'cannot_get_user_data'
      }
    }
    state.loading = false
  }
  useEffect(() => {
    if (state.banned) {
      onBan()
    }
  }, [state.banned, state.activeStory, state.profilePanel])
  const getEmail = async () => {
    try {
      const data = await connect.sendPromise('VKWebAppGetEmail')
      // Handling received data
      console.log('received email data', data)
      if (!data.email) {
        state.activeModal = 'email_not_confirmed'
        return
      }
    } catch (e) {
      console.log('Cannot get email data', error)
      // Handling an error
      state.activeModal = 'cannot_get_email'
    }
  }
  const signIn = async () => {
    await getUserData()
  }
  const onChangeStory = (story) => {
    if (state.banned) {
      onBan()
      return
    }
    console.log('Changing story to', story)
    state.activeStory = story
  }
  const onGameStart = (game) => {
    state.game = game
    state.activeStory = 'current_game'
    state.gamePanel = 'game'
  }
  const setActiveOptionsModal = (modal_id, modalParams) => {
    state.modalParams = modalParams
    state.activeModal = modal_id
  }
  const onShowSnackbar = (text) => {
    state.snackbar = <Snackbar
      layout="vertical"
      duration={2000}
      onClose={() => { state.snackbar = null }}
    >
      {text}
    </Snackbar>
  }
  const onChatMessage = (message) => {
    state.messages.push(message)
  }
  useEffect(() => {
    console.log('Token ADDED', state.token)
  }, [state.token])
  const wsUrl = process.env.NODE_ENV !== 'production' ? 'ws://localhost:4000/socket' : 'wss://crocapp.gigalixirapp.com/socket'
  return useObserver(() => (
    <PhoenixSocketProvider wsUrl={wsUrl} userToken={state.token}>
      <Suspense fallback={<ScreenSpinner/>}>
        <SnackbarContainer
          snackbar={state.snackbar}
        />
        <Modals
          onClose={() => { state.activeModal = null }}
          onSignIn={signIn}
          onGetUserData={getUserData}
          errorMessage={state.errorMessage}
          activeModal={state.activeModal}
          setActiveModal={setActiveModal}
          params={state.modalParams}
        />
        <Epic
          activeStory={state.activeStory}
          tabbar={<AppTabbar user={state.user} activeStory={state.activeStory} onChangeStory={onChangeStory} />}
        >
          <ProfileView
            id={'profile'}
            ban_id={state.ban_id}
            signIn={signIn}
            activePanel={state.profilePanel}
            user={state.user}
          />
          {
            state.loading
              ? (
                <View id={'find_game'}>
                  <PanelHeader>Найти игру</PanelHeader>
                  <PanelSpinner height={200} size={'large'}/>
                </View>
              )
              : (
                <LobbyView
                  {...props}
                  signIn={signIn}
                  user={state.user}
                  id={'find_game'}
                  onGameStart={onGameStart}
                  setActiveModal={setActiveModal}
                  setActiveOptionsModal={setActiveOptionsModal}
                />
              )
          }
          <GameView
            id={'current_game'}
            game={state.game}
            // game={mock_game}
            activePanel={state.gamePanel}
            user={state.user}
            onShowSnackbar={onShowSnackbar}
            onGameEnd={(game) => {
              state.endedGame = game
              state.activeStory = 'ended_game'
              state.gamePanel = 'no_game'
              state.game = null
            }}
            onChangeStory={onChangeStory}
            setActiveOptionsModal={setActiveOptionsModal}
            setActiveModal={setActiveModal}
            messages={state.messages}
            onChatMessage={onChatMessage}
          />
          <View
            id={'ended_game'}
            game={state.endedGame}
            activePanel={'main'}
            user={state.user}
            onChangeStory={onChangeStory}
            setActiveOptionsModal={setActiveOptionsModal}
          >
            <Panel id={'main'}>
              <PanelHeader>Игра окончена</PanelHeader>
              {
                state.endedGame
                  ? (
                    <Div>Победитель: {state.endedGame.winners[0] || 'Unknown error'}</Div>
                  )
                  : null
              }
            </Panel>
          </View>
        </Epic>
      </Suspense>
    </PhoenixSocketProvider>
  ))
}

export default VkMiniApp
