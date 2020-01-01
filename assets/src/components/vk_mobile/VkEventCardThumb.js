import React from 'react'
import { useObserver } from 'mobx-react-lite'

function VkEventCardThumb(props) {
  return useObserver(() => (
    <div style={{ width: 70 }} onClick={props.onClick}>
      <img
        style={{ width: 'inherit' }}
        src={props.src}
      />
    </div>
  ))
}

export default VkEventCardThumb
