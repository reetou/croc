import { flatten, groupBy, without } from 'lodash-es'
import { toJS } from 'mobx'

const getWidth = (form) => {
  switch (form) {
    case 'vertical-flip':
    case 'vertical':
      return 60
    default: return 110
  }
}

const getAngle = (form) => {
  switch (form) {
    case 'vertical-flip': return -90
    case 'vertical': return -90
    default: return 0
  }
}

const getMobileWidth = (form) => {
  switch (form) {
    case 'square': return 116
    default: return 137
  }
}

const getMobileHeight = (form) => {
  switch (form) {
    case 'square': return 116
    default: return 55
  }
}

const getSpriteWidth = (form) => {
  return 116
  switch (form) {
    case 'vertical-flip':
    case 'vertical':
      return 55
    case 'square': return 116
    default: return 116
  }
}

const getSpriteHeight = (form) => {
  switch (form) {
    case 'square': return 116
    case 'vertical-flip':
    case 'vertical':
      return 55
    default: return 55
  }
}

const getHeight = (form) => {
  switch (form) {
    case 'vertical-flip':
    case 'vertical':
    case 'square':
      return 110
    default: return 40
  }
}

const getTagPoint = (form) => {
  switch (form) {
    case 'vertical-flip':
      return {
        x: 0,
        y: 3,
        angle: 90,
      }
    case 'vertical':
      return {
        x: getSpriteWidth(form) + 21,
        y: 24,
        angle: 90
      }
    case 'horizontal-flip':
      return {
        x: 0,
        y: 52,
        angle: 270,
      }
    default:
      return {
        x: 137,
        y: 3,
        angle: 90
      }
  }
}

const getUpgradeTagPoint = (form) => {
  switch (form) {
    case 'vertical-flip':
      return {
        x: 15,
        y: 18,
        angle: 90,
      }
    case 'vertical':
      return {
        x: getSpriteWidth(form) + 5,
        y: 38,
        angle: 90
      }
    case 'horizontal-flip':
      return {
        x: 15,
        y: 38,
        angle: 270,
      }
    default:
      return {
        x: getSpriteWidth(form) + 5,
        y: 17,
        angle: 90
      }
  }
}

const getUpgradeLevelText = (upgrade_level) => {
  switch (upgrade_level) {
    case 2: return 'II'
    case 3: return 'III'
    case 4: return 'IV'
    case 5: return 'V'
    default: return 'I'
  }
}

const getUpgradeLevelTextPosition = (upgrade_level) => {
  switch (upgrade_level) {
    case 2: return {
      x: 7,
      y: 4
    }
    case 3: return {
      x: 5.5,
      y: 4
    }
    case 4: return {
      x: 5,
      y: 4
    }
    case 5: return {
      x: 7,
      y: 4,
    }
    default: return {
      x: 8.5,
      y: 4
    }
  }
}

const getHorizontalPlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [30, 20]
    case 1: return [60, 20]
    case 2: return [90, 20]
    case 3: return [30, 50]
    case 4: return [60, 50]
    case 5: return [90, 50]
  }
}
const getHorizontalFlipPlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [50, 23]
    case 1: return [80, 23]
    case 2: return [110, 23]
    case 3: return [50, 52]
    case 4: return [80, 52]
    case 5: return [110, 52]
  }
}
const getVerticalPlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [42, -85]
    case 1: return [42, -55]
    case 2: return [42, -25]
    case 3: return [72, -85]
    case 4: return [72, -55]
    case 5: return [72, -25]
  }
}
const getVerticalFlipPlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [20, -85]
    case 1: return [20, -55]
    case 2: return [20, -25]
    case 3: return [50, -85]
    case 4: return [50, -55]
    case 5: return [50, -25]
  }
}
const getSquarePlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [30, 30]
    case 1: return [60, 30]
    case 2: return [90, 30]
    case 3: return [30, 80]
    case 4: return [60, 80]
    case 5: return [90, 80]
  }
}
const getPosition = (form, ind) => {
  switch (form) {
    case 'square':
      return getSquarePlayerPosition(ind)
    case 'horizontal-flip':
      return getHorizontalFlipPlayerPosition(ind)
    case 'horizontal':
      return getHorizontalPlayerPosition(ind)
    case 'vertical-flip':
      return getVerticalFlipPlayerPosition(ind)
    case 'vertical':
      return getVerticalPlayerPosition(ind)
  }
}

const getCompletedMonopolies = (cards) => {
  const brandCards = cards.filter(c => c.type === 'brand')
  console.log('Groups', groupBy(brandCards, 'monopoly_type'))
  const groups = Object.values(groupBy(brandCards, 'monopoly_type'))
    .filter(group => {
      const card = group.find(c => c.owner)
      if (!card) return false
      return without(group.map(c => c.owner), card.owner).length === 0
    })
  console.log(`Groups with monopolies`, toJS(groups))
  return flatten(groups)
}

const getPositionsForEventCard = (type, cards, completedMonopolies) => {
  switch (type) {
    case 'force_auction':
      const result = cards
        .filter(c => c.owner)
        .filter(c => c.type === 'brand')
        .filter(c =>
          !completedMonopolies
            .map(z => z.monopoly_type)
            .includes(c.monopoly_type)
        )
      return result
    case 'force_sell_loan':
      return cards.filter(c => c.on_loan && c.owner)
    case 'force_teleportation':
      return cards
    default: return []
  }
}

const getEventCardCost = (type, game) => {
  switch (type) {
    case 'force_auction':
      return 1000
    case 'force_sell_loan':
      const monopolyCards = getCompletedMonopolies(game.cards)
        .map(c => c.monopoly_type)
      return game.cards.filter(c => c.on_loan && !monopolyCards.includes(c.monopoly_type)).length * 750
    case 'force_teleportation':
      return (game.players.filter(p => !p.surrender).length - 1) * 1000
    default: return 'Цена не указана'
  }
}

export {
  getMobileHeight,
  getMobileWidth,
  getHeight,
  getUpgradeTagPoint,
  getWidth,
  getSpriteWidth,
  getUpgradeLevelTextPosition,
  getSpriteHeight,
  getTagPoint,
  getAngle,
  getUpgradeLevelText,
  getPosition,
  getPositionsForEventCard,
  getCompletedMonopolies,
  getEventCardCost,
}
