-- | Halogen component that manages a Chart.js canvas lifecycle.
module Chartjs.Halogen
  ( component
  , Output(..)
  ) where

import Prelude

import Chartjs.Callbacks (Callbacks, ComponentInput, buildOverlays, hasOverlays)
import Chartjs.Config (toChartJsConfig)
import Chartjs.FFI (ChartInstance, createChart, updateChart, destroyChart, createChartWithCallbacks, updateChartWithCallbacks)
import Chartjs.Types (ChartConfig)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Exception (message, try)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP

-- | Output messages emitted by the chart component.
data Output = ChartError String

type State =
  { config :: ChartConfig
  , callbacks :: Callbacks
  , chart :: Maybe ChartInstance
  }

data Action
  = Initialize
  | Receive ComponentInput
  | Finalize

canvasRef :: H.RefLabel
canvasRef = H.RefLabel "chartjs-canvas"

-- | Halogen component that renders and manages a Chart.js chart.
component :: forall query m. MonadAff m => H.Component query ComponentInput Output m
component =
  H.mkComponent
    { initialState: \input -> { config: input.config, callbacks: input.callbacks, chart: Nothing }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , receive = Just <<< Receive
        , initialize = Just Initialize
        , finalize = Just Finalize
        }
    }

render :: forall m. State -> H.ComponentHTML Action () m
render _ =
  HH.canvas [ HP.ref canvasRef ]

handleAction :: forall m. MonadAff m => Action -> H.HalogenM State Action () Output m Unit
handleAction = case _ of
  Initialize -> do
    st <- H.get
    mEl <- H.getHTMLElementRef canvasRef
    case mEl of
      Nothing -> pure unit
      Just el -> do
        let json = toChartJsConfig st.config
        result <- liftEffect $ try $
          if hasOverlays st.callbacks st.config then
            createChartWithCallbacks el json (buildOverlays st.callbacks st.config)
          else
            createChart el json
        case result of
          Right inst -> H.modify_ _ { chart = Just inst }
          Left err -> H.raise (ChartError (message err))

  Receive input -> do
    H.modify_ _ { config = input.config, callbacks = input.callbacks }
    mInst <- H.gets _.chart
    case mInst of
      Nothing -> pure unit
      Just inst -> do
        let json = toChartJsConfig input.config
        result <- liftEffect $ try $
          if hasOverlays input.callbacks input.config then
            updateChartWithCallbacks inst json (buildOverlays input.callbacks input.config)
          else
            updateChart inst json
        case result of
          Right _ -> pure unit
          Left err -> H.raise (ChartError (message err))

  Finalize -> do
    mInst <- H.gets _.chart
    case mInst of
      Nothing -> pure unit
      Just inst -> liftEffect $ destroyChart inst
