import { Viewport } from "pixi-viewport";
import { PixiComponent } from "@inlet/react-pixi";

function init(props, instance) {
  const viewport = instance || new Viewport({
    screenWidth: window.innerWidth,
    screenHeight: window.innerHeight,
    worldWidth: 1000,
    worldHeight: 770,
    ticker: props.app ? props.app.ticker : false,
    interaction: props.app && props.app.renderer ? props.app.renderer.plugins.interaction : false
  });
  viewport.on("drag-start", () => {
    if (props.disableFieldInteraction) {
      props.disableFieldInteraction()
    }
  });
  viewport.on("drag-end", () => {
    if (props.enableFieldInteraction) {
      props.enableFieldInteraction()
    }
  });

  viewport
    .drag()
    .pinch()
    .wheel()
    .decelerate()
    // .bounce({
    //   friction: 0.3
    // })
    // .fit(true, 1000, 770)
    // .clampZoom({
    //   minWidth: 100,
    //   maxWidth: 1200,
    //   maxHeight: 900,
    // })
  return viewport;
}

export default PixiComponent("Viewport", {
  create: props => {
    return init(props)
  },
  applyProps: (instance, oldProps, newProps) => {
    // return init(newProps, instance)
    return instance
  },
  didMount: (instance, parent) => {
  },
  willUnmount: () => {
  }
});
