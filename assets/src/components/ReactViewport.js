import { Viewport } from "pixi-viewport";
import { PixiComponent } from "@inlet/react-pixi";

export default PixiComponent("Viewport", {
  create: props => {
    console.log('Props at view port component', props)
    const viewport = new Viewport({
      screenWidth: window.innerWidth,
      screenHeight: window.innerHeight,
      worldWidth: 1000,
      worldHeight: 770,
      ticker: props.app.ticker,
      interaction: props.app.renderer.plugins.interaction // the interaction module is important for wheel to work properly when renderer.view is placed or scaled
    });
    viewport.on("drag-start", () => {
      if (props.disableFieldInteraction) {
        props.disableFieldInteraction()
      }
      console.log("drag-start")
    });
    viewport.on("drag-end", () => {
      if (props.enableFieldInteraction) {
        props.enableFieldInteraction()
      }
      console.log("drag-end")
    });

    viewport
      .drag()
      .pinch()
      .wheel()
      .decelerate()
      .bounce({
        friction: 0.3
      })
      .fit(true, 1000, 770)
      .clampZoom({
        minWidth: 100,
        maxWidth: 1200,
        maxHeight: 900,
      })
    return viewport;
  },
  applyProps: (instance, oldProps, newProps) => {
    console.log("applyProps");
  },
  didMount: () => {
    console.log("didMount");
  },
  willUnmount: () => {
    console.log("willUnmount");
  }
});
