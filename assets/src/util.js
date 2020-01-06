
const getWidth = (form) => {
  switch (form) {
    case 'vertical-flip':
    case 'vertical':
      return 60
    default: return 110
  }
}

const getMobileWidth = (form) => {
  switch (form) {
    case 'vertical-flip':
    case 'vertical':
      return 55
    case 'square': return 116
    default: return 137
  }
}

const getMobileHeight = (form) => {
  switch (form) {
    case 'vertical-flip':
    case 'vertical':
      return 137
    case 'square': return 116
    default: return 55
  }
}

const getSpriteWidth = (form) => {
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
    case 'vertical-flip':
    case 'vertical':
      return 108
    case 'square': return 116
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
        x: 3,
        y: getSpriteHeight(form)
      }
    case 'vertical':
      return {
        x: 3,
        y: 0
      }
    case 'horizontal-flip':
      return {
        x: 0,
        y: 3
      }
    default:
      return {
        x: getSpriteWidth(form),
        y: 3
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
  getTagPoint
}
