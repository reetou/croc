import React from 'react'
import { useObserver } from 'mobx-react-lite'

function VkEventCardThumb(props) {
  return useObserver(() => (
    <div style={{ width: props.width || 70 }} onClick={props.onClick}>
      <img
        style={{
          width: 'inherit',
          ...props.rotate ? { transform: `rotate(${props.rotate}deg)` } : {}
        }}
        src={props.src}
      />
    </div>
  ))
}

export default VkEventCardThumb
