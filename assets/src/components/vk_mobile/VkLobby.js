import React, { useEffect } from 'react'
import { useObserver } from 'mobx-react-lite'
import { Div, UsersStack, Button } from '@vkontakte/vkui'

function VkLobby(props) {
  const {
    lobby,
    onJoin,
    canJoin,
    member,
    leaveLobby,
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
            photos={lobby.players.map(p => p.image_url)}
            size="m"
            layout="vertical"
            visibleCount={5}
            style={{ color: "#fff" }}
          >
            {lobby.players.length} игроков в лобби{member ? ', включая вас' : null}
          </UsersStack>
          {
            member
              ? (
                <Button
                  level="outline"
                  disabled={!member}
                  onClick={leaveLobby}
                >
                  Выйти
                </Button>
              )
              : (
                <Button
                  level="outline"
                  disabled={!canJoin}
                  onClick={onJoin}
                >
                  Присоединиться
                </Button>
              )
          }
        </div>
      </Div>
    </React.Fragment>
  ))
}

export default VkLobby
