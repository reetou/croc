import React, { useEffect } from 'react'
import { useObserver } from 'mobx-react-lite'
import { Div, UsersStack, Button } from '@vkontakte/vkui'

function VkLobby(props) {
  const {
    lobby,
    onJoin,
    canJoin,
    member,
    onGoToLobby,
    leaveLobby,
  } = props
  return useObserver(() => (
    <React.Fragment>
      <Div>
        <div style={{
          backgroundImage: 'linear-gradient(135deg, #f24973 0%, #3948e6 100%)',
          height: 120,
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
            {lobby.players.length} игроков в лобби{member && lobby.players.length > 1 ? ', включая вас' : null}
          </UsersStack>
          {
            member
              ? (
                <Div style={{display: 'flex'}}>
                  <Button
                    onClick={onGoToLobby}
                    disabled={!member}
                    mode={'primary'}
                    stretched
                    style={{ marginRight: 8 }}
                  >
                    Перейти
                  </Button>
                  <Button
                    stretched
                    mode="overlay_secondary"
                    disabled={!member}
                    onClick={leaveLobby}
                  >
                    Выйти
                  </Button>
                </Div>
              )
              : (
                <Div>
                  <Button
                    level="outline"
                    disabled={!canJoin}
                    onClick={onJoin}
                  >
                    Присоединиться
                  </Button>
                </Div>
              )
          }
        </div>
      </Div>
    </React.Fragment>
  ))
}

export default VkLobby
