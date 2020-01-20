import { Sprite, Container } from '@inlet/react-pixi'
import React from 'react'
import { useAsObservableSource } from 'mobx-react-lite'

function MapButtonsContainer(props) {
  const state = useAsObservableSource(props)
  const {
    isLandscape,
    zoomIn,
    zoomOut,
    follow,
  } = state
  return (
    <Container
      name="map_buttons"
      y={isLandscape ? 48 : state.stageHeight - 32 - 16 * 3 - 2 * 3}
    >
      <Sprite
        x={state.stageWidth - 16}
        y={0}
        width={16}
        height={16}
        interactive
        click={zoomIn}
        tap={zoomIn}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/zoom-in.png'}
      />
      <Sprite
        x={state.stageWidth - 16}
        y={18}
        width={16}
        height={16}
        interactive
        click={zoomOut}
        tap={zoomOut}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/zoom-out.png'}
      />
      <Sprite
        visible={!state.following}
        x={state.stageWidth - 16}
        y={36}
        width={16}
        height={16}
        interactive
        click={follow}
        tap={follow}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/follow.png'}
      />
      <Sprite
        visible={state.following}
        x={state.stageWidth - 16}
        y={36}
        width={16}
        height={16}
        interactive
        click={follow}
        tap={follow}
        image={'https://croc-images.fra1.cdn.digitaloceanspaces.com/icons/follow-active.png'}
      />
    </Container>
  )
}

export default MapButtonsContainer
