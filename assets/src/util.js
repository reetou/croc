
const getWidth = (form) => {
  switch (form) {
    case 'vertical': return 60
    default: return 110
  }
}

const getMobileWidth = (form, maxWidth = window.innerWidth) => {
  switch (form) {
    case 'vertical': return 30
    default: return maxWidth / 4
  }
}

const getMobileHeight = (form) => {
  switch (form) {
    case 'vertical': return 60
    default: return 40
  }
}

const getHeight = (form) => {
  switch (form) {
    case 'vertical':
    case 'square': return 110
    default: return 40
  }
}

export {
  getMobileHeight,
  getMobileWidth,
  getHeight,
  getWidth
}
