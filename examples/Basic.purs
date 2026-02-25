-- | Basic example of using purescript-chartjs.
-- | This file is for documentation only — it is not compiled as part of the library.
module Examples.Basic where

import Prelude

import Chartjs.Halogen as Chart
import Chartjs.Types (ChartType(..), defaultConfig, defaultDataset, defaultOptions, defaultPluginsConfig, defaultTitleConfig, defaultScaleConfig, fromNumbers, single, perItem, css)
import Chartjs.Callbacks (simpleInput, defaultCallbacks, ComponentInput)
import Data.Maybe (Maybe(..))
import Data.Tuple (Tuple(..))
import Effect.Uncurried (mkEffectFn3)
import Foreign.Object as Object
import Halogen as H
import Halogen.HTML as HH
import Type.Proxy (Proxy(..))

-- ============================================================================
-- Simple bar chart (no callbacks)
-- ============================================================================

simpleBarChart :: ComponentInput
simpleBarChart = simpleInput $ defaultConfig
  { chartType = Bar
  , labels = ["Jan", "Feb", "Mar", "Apr"]
  , datasets =
      [ defaultDataset
          { label = "Revenue"
          , "data" = fromNumbers [100.0, 200.0, 150.0, 300.0]
          , backgroundColor = single (css "#4CAF50")
          }
      , defaultDataset
          { label = "Expenses"
          , "data" = fromNumbers [80.0, 150.0, 120.0, 200.0]
          , backgroundColor = single (css "#F44336")
          }
      ]
  , options = defaultOptions
      { plugins = Just defaultPluginsConfig
          { title = Just defaultTitleConfig
              { display = Just true
              , text = Just "Monthly Revenue vs Expenses"
              }
          }
      , scales = Just $ Object.fromFoldable
          [ Tuple "y" $ defaultScaleConfig { beginAtZero = Just true }
          ]
      }
  }

-- ============================================================================
-- Chart with onClick callback
-- ============================================================================

chartWithCallbacks :: ComponentInput
chartWithCallbacks =
  { config: defaultConfig
      { chartType = Pie
      , labels = ["Red", "Blue", "Yellow"]
      , datasets =
          [ defaultDataset
              { label = "Votes"
              , "data" = fromNumbers [12.0, 19.0, 3.0]
              , backgroundColor = perItem [css "#FF6384", css "#36A2EB", css "#FFCE56"]
              }
          ]
      }
  , callbacks: defaultCallbacks
      { onClick = Just $ mkEffectFn3 \_ elements _ -> do
          -- Handle click on chart elements
          pure unit
      }
  }

-- ============================================================================
-- Using the component in a Halogen parent
-- ============================================================================

_chart :: Proxy "chart"
_chart = Proxy

-- | Example parent component rendering a chart.
-- | In a real app, you'd handle Chart.Output if you want error notifications:
-- |
-- |   HH.slot _chart unit Chart.component simpleBarChart handleOutput
-- |
-- | where handleOutput (Chart.ChartError msg) = ... log the error ...
-- |
-- | Or ignore output with slot_:
exampleRender :: forall w i. HH.HTML w i
exampleRender =
  HH.div_
    [ HH.h1_ [ HH.text "My Charts" ]
    , HH.slot_ _chart unit Chart.component simpleBarChart
    ]
