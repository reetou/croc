import React from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Avatar,
  Button,
  Cell,
  FixedLayout,
  FormLayout,
  HeaderButton,
  FormLayoutGroup,
  Input,
  List,
  PanelHeader,
  PanelHeaderContent,
} from '@vkontakte/vkui'

function Chat(props) {
  const state = useLocalStore((source) => ({
    messages: source.messages,
    text: '',
    to: null,
  }), props)
  return useObserver(() => (
    <React.Fragment>
      <PanelHeader
        left={<HeaderButton onClick={props.onGoBack}>Назад</HeaderButton>}
      >
        <PanelHeaderContent>
          Чат
        </PanelHeaderContent>
      </PanelHeader>
      <List style={{ minHeight: '65vh' }}>
        {
          state.messages.map(m => (
            <Cell
              multiline
              before={(
                <Avatar
                  size={24}
                  src="https://pp.userapi.com/c841034/v841034569/3b8c1/pt3sOw_qhfg.jpg"
                />
              )}
            >
              {m.text}
            </Cell>
          ))
        }
      </List>
      <FormLayout>
        <FormLayoutGroup>
          <Input
            type="text"
            value={state.text}
            onChange={e => {
              state.text = e.target.value
            }}
          />
          <div style={{ display: 'flex', justifyContent: 'space-between' }}>
            <Button
              disabled
            >
              Всем
            </Button>
            <Button
              align="center"
              onClick={() => {
                props.sendMessage(state.to, state.text)
                state.text = ''
              }}
            >
              Отправить
            </Button>
          </div>
        </FormLayoutGroup>
      </FormLayout>
    </React.Fragment>
  ))
}

export default Chat
