# chartjs-halogen

A [Halogen](https://github.com/purescript-halogen/purescript-halogen) component for [Chart.js](https://www.chartjs.org/), built on top of [`chartjs`](../core/).

This is the Halogen wrapper package of [purescript-chartjs](../README.md). For framework-agnostic usage, see [`chartjs`](../core/).

## Installation

Add to your `spago.yaml` `extraPackages`:

```yaml
extraPackages:
  chartjs:
    git: https://your-gitea-instance/you/purescript-chartjs.git
    ref: main
    subdir: core
  chartjs-halogen:
    git: https://your-gitea-instance/you/purescript-chartjs.git
    ref: main
    subdir: halogen
```

Then add the dependencies:

```yaml
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
    [ HH.slot_ _chart unit Chart.component myChart ]
```

## Error Handling

The component emits `ChartError String` as output when Chart.js throws:

```purescript
HH.slot _chart unit Chart.component myInput handleOutput

handleOutput :: Chart.Output -> _
handleOutput (Chart.ChartError msg) = -- log or display the error
```

## Component Lifecycle

1. **Initialize** -- creates a `<canvas>`, instantiates Chart.js via FFI
2. **Receive** -- on input change, calls `chart.update()` (no destroy/recreate)
3. **Finalize** -- calls `chart.destroy()` to prevent memory leaks

## License

Apache-2.0
