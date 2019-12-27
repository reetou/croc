import React, { useState, useEffect } from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import { Stage, Sprite } from '@inlet/react-pixi'
import Field from './Field'
import { useKey } from 'react-use'
import _ from 'lodash-es'
import { toJS } from 'mobx'
import styled from 'styled-components'
import PlayerSprite from './PlayerSprite'
import * as PIXI from 'pixi.js'
PIXI.useDeprecated();

window.__PIXI_INSPECTOR_GLOBAL_HOOK__ &&
window.__PIXI_INSPECTOR_GLOBAL_HOOK__.register({ PIXI: PIXI });

const mock_game = {
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
      "monopoly_type": "props.games",
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
      "monopoly_type": "props.games",
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
  "event_cards": [],
  "props.game_id": "59979686-8ae0-4e41-a4e9-72b94b4c5259",
  "on_timeout": null,
  "player_turn": 16,
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
      "player_id": 16,
      "position": 0,
      "surrender": false
    }
  ],
  "round": 1,
  "started_at": "2019-12-24T00:18:08Z",
  "turn_timeout_at": null,
  "winners": []
}

const TableContainer = styled.div`
  .container {
    margin-left: 0 !important;
    margin-right: 0 !important;
  }
`

function GameTable(props) {
  const [enabled, setEditor] = useState(false)
  const state = useLocalStore(() => ({
    fieldSettings: []
  }))
  useKey((e) => e.code === 'keyS', () => {
    if (!enabled) return
    _.set(state, `fieldSettings.${active}.form`, 'square')
  })
  useKey((e) => e.code === 'keyV', () => {
    if (!enabled) return
    _.set(state, `fieldSettings.${active}.form`, 'vertical')
  })
  useKey((e) => e.code === 'keyH', () => {
    if (!enabled) return
    _.set(state, `fieldSettings.${active}.form`, 'horizontal')
  })
  const [active, setActive] = useState(null)
  const [old, setOld] = useState(0)
  useEffect(() => {
    if (!enabled) {
      setActive(null)
    }
  }, [enabled])
  useEffect(() => {
    const oldSettings = localStorage.getItem('map')
    if (oldSettings) {
      console.log('Loading old settings', JSON.parse(oldSettings))
      state.fieldSettings = JSON.parse(oldSettings)
    } else {
      state.fieldSettings = props.game.cards.map(c => ({
        form: 'horizontal',
        point: {
          x: 600,
          y: 100,
        }
      }))
    }
  }, [])
  return useObserver(() => (
    <TableContainer>
      <button onClick={() => setEditor(!enabled)}>Editor mode: {enabled ? 'enabled' : 'disabled'}</button>
      <button
        onClick={() => {
          localStorage.setItem('map', JSON.stringify(toJS(state.fieldSettings)))
          console.log('Set', toJS(state.fieldSettings))
          alert('Успешно')
        }}
      >
        Сохранить
      </button>
      <button
        onClick={() => {
          localStorage.removeItem('map')
          window.location.reload()
        }}
      >
        Сбросить
      </button>
      <h1>Active {active}</h1>
      <Stage options={{ backgroundColor: 0x10bb99, height: 600, width: window.innerWidth - 90 }}>
        {
          state.fieldSettings && state.fieldSettings.length
            ? (
              <React.Fragment>
                {
                  props.game.cards.map(c => {
                    const playerOwner = c.owner ? props.game.players.find(p => p.player_id === c.owner) : null
                    const color = playerOwner ? playerOwner.color : false
                    return (
                      <Field
                        color={color}
                        enabled={enabled}
                        card={c}
                        key={c.id}
                        form={state.fieldSettings[c.position].form}
                        click={() => {
                          if (!enabled) return
                          setOld(active)
                          setActive(c.position)
                        }}
                        x={state.fieldSettings[c.position].point.x}
                        y={state.fieldSettings[c.position].point.y}
                        onSubmitPoint={(v) => {
                          _.set(state, `fieldSettings.${c.position}.point.x`, v[0])
                          _.set(state, `fieldSettings.${c.position}.point.y`, v[1])
                        }}
                      />
                    )
                  })
                }
                {
                  props.game.players.map(p => (
                    <PlayerSprite
                      image="https://s3-us-west-2.amazonaws.com/s.cdpn.io/693612/coin.png"
                      key={p.player_id}
                      squares={(
                        props.game.cards
                          .filter(c => {
                            if (!state.fieldSettings[c.position]) return false
                            return state.fieldSettings[c.position].form === 'square'
                          })
                          .map(c => {
                            const point = state.fieldSettings[c.position].point
                            return {
                              ...c,
                              point
                            }
                          })
                      )}
                      player_id={p.player_id}
                      color={p.color}
                      position={p.position}
                      old_position={p.old_position}
                      enabled={enabled}
                      x={state.fieldSettings[p.position].point.x}
                      y={state.fieldSettings[p.position].point.y}
                    />
                  ))
                }
              </React.Fragment>
            )
            : null
        }
      </Stage>
    </TableContainer>
  ))
}

export default GameTable
