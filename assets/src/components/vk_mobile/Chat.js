import React from 'react'
import { useLocalStore, useObserver } from 'mobx-react-lite'
import {
  Avatar,
  Button,
  Cell,
  FormLayout,
  PanelHeaderButton,
  FormLayoutGroup,
  Input,
  Group,
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
        left={<PanelHeaderButton onClick={props.onGoBack}>Назад</PanelHeaderButton>}
      >
        <PanelHeaderContent>
          Чат
        </PanelHeaderContent>
      </PanelHeader>
      <List style={{ minHeight: '65vh' }}>
        {
          state.messages.map(m => (
            <Group>
              <Cell
                before={(
                  <Avatar
                    size={36}
                    src={m.image_url}
                  />
                )}
                multiline
              >
                <div>
                  {m.name}
                </div>
                <div>
                  {m.text}
                </div>
              </Cell>
            </Group>
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
