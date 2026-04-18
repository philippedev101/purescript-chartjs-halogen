-- | Halogen component that manages a Chart.js canvas lifecycle.
-- |
-- | Wraps `purescript-chartjs` FFI bindings in a Halogen component with:
-- | - Automatic create/update/destroy on mount/receive/unmount
-- | - `updateMode` support to suppress animation on data updates
-- | - Query interface for all Chart.js instance methods
-- | - `ChartReady` output when the instance is available
module Chartjs.Halogen
  ( component
  , Query(..)
  , Output(..)
  ) where

import Prelude

import Chartjs.Callbacks (Callbacks, ComponentInput, buildOverlays, hasOverlays)
import Chartjs.Config (toChartJsConfig)
import Chartjs.FFI as FFI
import Chartjs.Types (ChartConfig, InteractionItem, InteractionMode, InteractionOptions)
import Data.Either (Either(..))
import Data.Maybe (Maybe(..))
import Effect.Aff.Class (class MonadAff)
import Effect.Class (liftEffect)
import Effect.Exception (message, try)
import Foreign (Foreign)
import Halogen as H
import Halogen.HTML as HH
import Halogen.HTML.Properties as HP
import Web.Event.Event (Event)

-- | Output messages emitted by the chart component.
data Output
  = ChartError String
  | ChartReady FFI.ChartInstance

-- | Queries for interacting with the chart instance.
-- | Use `H.request` for queries that return a value, `H.tell` for fire-and-forget.
data Query a
  = ToBase64Image (Maybe String) (Maybe Number) (String -> a)
  | StopChart a
  | ResetChart a
  | RenderChart a
  | ClearChart a
  | ResizeChart (Maybe Number) (Maybe Number) a
  | SetDatasetVisibility Int Boolean a
  | IsDatasetVisible Int (Boolean -> a)
  | HideDataset Int (Maybe Int) a
  | ShowDataset Int (Maybe Int) a
  | ToggleDataVisibility Int a
  | GetDataVisibility Int (Boolean -> a)
  | GetActiveElements (Array Foreign -> a)
  | SetActiveElements (Array { datasetIndex :: Int, index :: Int }) a
  | GetDatasetMeta Int (Foreign -> a)
  | GetElementsAtEventForMode Event InteractionMode InteractionOptions Boolean (Array InteractionItem -> a)
  | GetVisibleDatasetCount (Int -> a)
  | GetSortedVisibleDatasetMetas (Array Foreign -> a)
  | IsPluginEnabled String (Boolean -> a)
  | IsPointInArea { x :: Number, y :: Number } (Boolean -> a)
  | GetChartContext (Foreign -> a)
  | NotifyPlugins String Foreign (Boolean -> a)
  | GetInstance (Maybe FFI.ChartInstance -> a)

type State =
  { config :: ChartConfig
  , callbacks :: Callbacks
  , updateMode :: Maybe String
  , chart :: Maybe FFI.ChartInstance
  }

data Action
  = Initialize
  | Receive ComponentInput
  | Finalize

canvasRef :: H.RefLabel
canvasRef = H.RefLabel "chartjs-canvas"

-- | Halogen component that renders and manages a Chart.js chart.
-- |
-- | Input: `ComponentInput` from `Chartjs.Callbacks` (config + callbacks + updateMode).
-- | Use `simpleInput` for the common case (no callbacks, animation suppressed on updates).
-- |
-- | Queries: All Chart.js instance methods are available via the `Query` type.
-- | Use `H.request` for methods that return values, `H.tell` for side-effect-only methods.
-- |
-- | Output: `ChartReady inst` when the chart is created (for consumers who need
-- | the raw instance), `ChartError msg` on create/update/query failures.
component :: forall m. MonadAff m => H.Component Query ComponentInput Output m
component =
  H.mkComponent
    { initialState: \input -> { config: input.config, callbacks: input.callbacks, updateMode: input.updateMode, chart: Nothing }
    , render
    , eval: H.mkEval H.defaultEval
        { handleAction = handleAction
        , handleQuery = handleQuery
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
            FFI.createChartWithCallbacks el json (buildOverlays st.callbacks st.config)
          else
            FFI.createChart el json
        case result of
          Right inst -> do
            H.modify_ _ { chart = Just inst }
            H.raise (ChartReady inst)
          Left err -> H.raise (ChartError (message err))

  Receive input -> do
    H.modify_ _ { config = input.config, callbacks = input.callbacks, updateMode = input.updateMode }
    mInst <- H.gets _.chart
    case mInst of
      Nothing -> pure unit
      Just inst -> do
        let json = toChartJsConfig input.config
        result <- liftEffect $ try $
          if hasOverlays input.callbacks input.config then
            FFI.updateChartWithCallbacks inst json (buildOverlays input.callbacks input.config) input.updateMode
          else
            FFI.updateChart inst json input.updateMode
        case result of
          Right _ -> pure unit
          Left err -> H.raise (ChartError (message err))

  Finalize -> do
    mInst <- H.gets _.chart
    case mInst of
      Nothing -> pure unit
      Just inst -> liftEffect $ FFI.destroyChart inst

handleQuery :: forall m a. MonadAff m => Query a -> H.HalogenM State Action () Output m (Maybe a)
handleQuery = case _ of
  -- GetInstance works even when chart is not initialized
  GetInstance k -> do
    mInst <- H.gets _.chart
    pure $ Just $ k mInst

  -- All other queries require a chart instance
  q -> do
    mInst <- H.gets _.chart
    case mInst of
      Nothing -> pure Nothing
      Just inst -> dispatchQuery inst q

dispatchQuery :: forall m a. MonadAff m => FFI.ChartInstance -> Query a -> H.HalogenM State Action () Output m (Maybe a)
dispatchQuery inst = case _ of
  ToBase64Image imgType quality k -> safeFFI $ do
    result <- FFI.toBase64Image inst imgType quality
    pure $ k result
  StopChart a -> safeFFI $ do
    void $ FFI.stopChart inst
    pure a
  ResetChart a -> safeFFI $ do
    FFI.resetChart inst
    pure a
  RenderChart a -> safeFFI $ do
    FFI.renderChart inst
    pure a
  ClearChart a -> safeFFI $ do
    void $ FFI.clearChart inst
    pure a
  ResizeChart w h a -> safeFFI $ do
    FFI.resizeChart inst w h
    pure a
  SetDatasetVisibility idx visible a -> safeFFI $ do
    FFI.setDatasetVisibility inst idx visible
    pure a
  IsDatasetVisible idx k -> safeFFI $ do
    result <- FFI.isDatasetVisible inst idx
    pure $ k result
  HideDataset datasetIdx dataIdx a -> safeFFI $ do
    FFI.hideDataset inst datasetIdx dataIdx
    pure a
  ShowDataset datasetIdx dataIdx a -> safeFFI $ do
    FFI.showDataset inst datasetIdx dataIdx
    pure a
  ToggleDataVisibility idx a -> safeFFI $ do
    FFI.toggleDataVisibility inst idx
    pure a
  GetDataVisibility idx k -> safeFFI $ do
    result <- FFI.getDataVisibility inst idx
    pure $ k result
  GetActiveElements k -> safeFFI $ do
    result <- FFI.getActiveElements inst
    pure $ k result
  SetActiveElements elements a -> safeFFI $ do
    FFI.setActiveElements inst elements
    pure a
  GetDatasetMeta idx k -> safeFFI $ do
    result <- FFI.getDatasetMeta inst idx
    pure $ k result
  GetElementsAtEventForMode event mode opts useFinal k -> safeFFI $ do
    result <- FFI.getElementsAtEventForMode inst event mode opts useFinal
    pure $ k result
  GetVisibleDatasetCount k -> safeFFI $ do
    result <- FFI.getVisibleDatasetCount inst
    pure $ k result
  GetSortedVisibleDatasetMetas k -> safeFFI $ do
    result <- FFI.getSortedVisibleDatasetMetas inst
    pure $ k result
  IsPluginEnabled pluginId k -> safeFFI $ do
    result <- FFI.isPluginEnabled inst pluginId
    pure $ k result
  IsPointInArea point k -> safeFFI $ do
    result <- FFI.isPointInArea inst point
    pure $ k result
  GetChartContext k -> safeFFI $ do
    result <- FFI.getChartContext inst
    pure $ k result
  NotifyPlugins hook args k -> safeFFI $ do
    result <- FFI.notifyPlugins inst hook args
    pure $ k result
  GetInstance _ ->
    -- Handled in handleQuery, unreachable here
    pure Nothing
  where
    safeFFI action = do
      result <- liftEffect $ try action
      case result of
        Right a -> pure $ Just a
        Left err -> do
          H.raise (ChartError (message err))
          pure Nothing
