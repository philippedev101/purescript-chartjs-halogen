# chartjs-halogen

A [Halogen](https://github.com/purescript-halogen/purescript-halogen) component for [Chart.js](https://www.chartjs.org/), built on top of [`purescript-chartjs`](https://github.com/philippedev101/purescript-chartjs).

## Installation

Both packages are in the PureScript registry:

```yaml
# spago.yaml
dependencies:
  - chartjs
  - chartjs-halogen
```

Install the JS dependency:

```
bun add chart.js
```

## Usage

```purescript
import Chartjs.Halogen as Chart
import Chartjs.Types (ChartType(..), defaultConfig, defaultDataset, defaultOptions,
  defaultPluginsConfig, defaultTitleConfig, fromNumbers, single, css)
import Chartjs.Callbacks (simpleInput)
import Data.Maybe (Maybe(..))
import Halogen.HTML as HH
import Type.Proxy (Proxy(..))

_chart = Proxy :: Proxy "chart"

myChart = simpleInput $ defaultConfig
  { chartType = Bar
  , labels = ["Jan", "Feb", "Mar", "Apr"]
  , datasets =
      [ defaultDataset
          { label = "Revenue"
          , "data" = fromNumbers [100.0, 200.0, 150.0, 300.0]
          , backgroundColor = single (css "#4CAF50")
          }
      ]
  , options = defaultOptions
      { plugins = Just defaultPluginsConfig
          { title = Just defaultTitleConfig
              { display = Just true, text = Just "Monthly Revenue" }
          }
      }
  }

render state =
  HH.div_
    [ HH.slot _chart unit Chart.component myChart handleOutput ]

handleOutput :: Chart.Output -> _
handleOutput = case _ of
  Chart.ChartReady inst -> -- chart instance is available
  Chart.ChartError msg  -> -- log or display the error
```

## Animation Control

By default, `simpleInput` sets `updateMode` to `Just "none"`, which suppresses animation when the chart data updates. This prevents the chart from re-animating on every Halogen re-render.

To use a different update mode:

```purescript
import Chartjs.Callbacks (defaultCallbacks)

myInput = { config: myConfig, callbacks: defaultCallbacks, updateMode: Just "active" }
-- or Nothing for the default Chart.js animation
```

## Queries

All Chart.js instance methods are available via the `Query` type. Use `H.request` for methods that return values and `H.tell` for fire-and-forget:

```purescript
-- Export chart as image
mUrl <- H.request _chart unit (Chart.ToBase64Image (Just "image/png") Nothing identity)

-- Reset animation state
H.tell _chart unit Chart.ResetChart

-- Stop ongoing animation
H.tell _chart unit Chart.StopChart

-- Resize chart
H.tell _chart unit (Chart.ResizeChart (Just 800.0) (Just 600.0))

-- Toggle dataset visibility
H.tell _chart unit (Chart.SetDatasetVisibility 0 false)

-- Get active (hovered) elements
mActive <- H.request _chart unit (Chart.GetActiveElements identity)

-- Programmatically highlight elements
H.tell _chart unit (Chart.SetActiveElements [{ datasetIndex: 0, index: 1 }])

-- Get raw ChartInstance for advanced usage
mInst <- H.request _chart unit (Chart.GetInstance identity)
```

### Available queries

| Query | Type | Description |
|-------|------|-------------|
| `ToBase64Image` | request | Export chart as base64 image URL |
| `StopChart` | tell | Stop current animation |
| `ResetChart` | tell | Reset to pre-animation state |
| `RenderChart` | tell | Trigger a redraw |
| `ClearChart` | tell | Clear the canvas |
| `ResizeChart` | tell | Resize to given dimensions (or container) |
| `SetDatasetVisibility` | tell | Show/hide a dataset by index |
| `IsDatasetVisible` | request | Check if a dataset is visible |
| `HideDataset` | tell | Hide dataset/element with animation |
| `ShowDataset` | tell | Show dataset/element with animation |
| `ToggleDataVisibility` | tell | Toggle a data element's visibility |
| `GetDataVisibility` | request | Check a data element's visibility |
| `GetActiveElements` | request | Get currently highlighted elements |
| `SetActiveElements` | tell | Programmatically highlight elements |
| `GetDatasetMeta` | request | Get dataset metadata (Foreign) |
| `GetElementsAtEventForMode` | request | Hit-test elements at an event |
| `GetVisibleDatasetCount` | request | Count visible datasets |
| `GetSortedVisibleDatasetMetas` | request | Get visible dataset metas in draw order |
| `IsPluginEnabled` | request | Check if a plugin is active |
| `IsPointInArea` | request | Check if a point is inside the chart area |
| `GetChartContext` | request | Get the chart context object |
| `NotifyPlugins` | request | Notify plugins of a lifecycle hook |
| `GetInstance` | request | Get the raw ChartInstance (or Nothing) |

## Output

The component emits two output messages:

- `ChartReady ChartInstance` -- emitted once after the chart is created. Use this if you need the raw instance for advanced operations.
- `ChartError String` -- emitted when Chart.js throws during create, update, or query execution.

## Component Lifecycle

1. **Initialize** -- creates a `<canvas>`, instantiates Chart.js, emits `ChartReady`
2. **Receive** -- on input change, calls `chart.update(mode)` with the configured `updateMode`
3. **Finalize** -- calls `chart.destroy()` to prevent memory leaks

## License

Apache-2.0
