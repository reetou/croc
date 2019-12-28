import React from 'react'
import { useObserver } from 'mobx-react-lite'

function SnackbarContainer(props) {
  return useObserver(() => (
    <React.Fragment>
      {props.snackbar}
    </React.Fragment>
  ))
}

export default SnackbarContainer
