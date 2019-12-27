import React, { useEffect } from 'react'
import { useObserver } from 'mobx-react-lite'
import { Div, UsersStack, Button } from '@vkontakte/vkui'

function VkLobby(props) {
  const {
    lobby,
    onJoin,
    canJoin,
  } = props
  return useObserver(() => (
    <React.Fragment>
      <Div>
        <div style={{
          backgroundImage: 'linear-gradient(135deg, #f24973 0%, #3948e6 100%)',
          height: 100,
          display: 'flex',
          flexDirection: 'column',
          alignItems: 'center',
          justifyContent: 'flex-end',
          paddingBottom: '6px',
          borderRadius: 12
        }}>
          <UsersStack
            photos={[
              'https://sun9-19.userapi.com/c851232/v851232757/fb949/4rDdDHqGglQ.jpg?ava=1',
              'https://sun9-3.userapi.com/c851536/v851536176/a9b1d/xdPOltpVQRI.jpg?ava=1',
              'https://sun9-21.userapi.com/c851416/v851416327/be840/bnUHAblZoBY.jpg?ava=1'
            ]}
            size="m"
            style={{ color: "#fff" }}
          />
          <Button
            level="outline"
            disabled={!canJoin}
            onClick={onJoin}
          >
            Присоединиться
          </Button>
        </div>
      </Div>
    </React.Fragment>
  ))
}

export default VkLobby
