
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

export {
  getMobileHeight,
  getMobileWidth,
  getHeight,
  getWidth,
  getSpriteWidth,
  getSpriteHeight,
  getTagPoint,
  getAngle
}
