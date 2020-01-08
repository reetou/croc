
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

const getHorizontalPlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [25, 15]
    case 1: return [55, 15]
    case 2: return [85, 15]
    case 3: return [25, 40]
    case 4: return [55, 40]
    case 5: return [85, 40]
  }
}
const getHorizontalFlipPlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [50, 15]
    case 1: return [80, 15]
    case 2: return [110, 15]
    case 3: return [50, 40]
    case 4: return [80, 40]
    case 5: return [110, 40]
  }
}
const getVerticalPlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [35, -85]
    case 1: return [35, -60]
    case 2: return [35, -35]
    case 3: return [60, -85]
    case 4: return [60, -60]
    case 5: return [60, -35]
  }
}
const getVerticalFlipPlayerPosition = (ind) => {
  switch (ind) {
    case 0: return [15, -85]
    case 1: return [15, -60]
    case 2: return [15, -35]
    case 3: return [40, -85]
    case 4: return [40, -60]
    case 5: return [40, -35]
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

export {
  getMobileHeight,
  getMobileWidth,
  getHeight,
  getWidth,
  getSpriteWidth,
  getSpriteHeight,
  getTagPoint,
  getAngle,
  getPosition,
}
