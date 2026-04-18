// Integration tests for the Halogen component's FFI dispatch layer.
// Verifies that each Query constructor's FFI call works against a real
// Chart.js instance in JSDOM.
//
// Run: bunx spago build && bun test test/integration/

import { test, expect, beforeEach, afterEach } from "bun:test";
import "./setup.js";
import { makeCanvas, minimalBarConfig } from "./setup.js";
// Import from compiled PureScript output (requires `bunx spago build` first)
import * as FFI from "../../output/Chartjs.FFI/foreign.js";

let chart;
let canvas;

beforeEach(() => {
  canvas = makeCanvas();
  chart = FFI.createChartImpl(canvas, minimalBarConfig());
});

afterEach(() => {
  if (chart) {
    FFI.destroyChartImpl(chart);
    chart = null;
  }
  if (canvas && canvas.parentNode) canvas.parentNode.removeChild(canvas);
});

// These tests mirror each Query constructor in Chartjs.Halogen to verify
// the FFI call the Halogen component dispatches actually works.

test("updateChartImpl with mode='none' (updateMode passthrough)", () => {
  const config = minimalBarConfig();
  config.data.datasets[0].data = [10, 20];
  FFI.updateChartImpl(chart, config, "none");
  expect(chart.data.datasets[0].data).toEqual([10, 20]);
});

test("updateChartImpl with mode=null (default animation)", () => {
  const config = minimalBarConfig();
  FFI.updateChartImpl(chart, config, null);
  // No crash is success
});

test("ToBase64Image: toBase64ImageImpl", () => {
  const url = FFI.toBase64ImageImpl(chart, null, null);
  expect(typeof url).toBe("string");
  expect(url.startsWith("data:")).toBe(true);
});

test("StopChart: stopChartImpl returns chart instance", () => {
  const result = FFI.stopChartImpl(chart);
  expect(result).toBe(chart);
});

test("ResetChart: resetChartImpl", () => {
  FFI.resetChartImpl(chart);
  // No crash is success
});

test("RenderChart: renderChartImpl", () => {
  FFI.renderChartImpl(chart);
});

test("ClearChart: clearChartImpl returns chart instance", () => {
  const result = FFI.clearChartImpl(chart);
  expect(result).toBe(chart);
});

test("ResizeChart: resizeChartImpl with null dimensions", () => {
  FFI.resizeChartImpl(chart, null, null);
});

test("ResizeChart: resizeChartImpl with explicit dimensions", () => {
  FFI.resizeChartImpl(chart, 800, 600);
});

test("SetDatasetVisibility: setDatasetVisibilityImpl", () => {
  FFI.setDatasetVisibilityImpl(chart, 0, false);
  expect(FFI.isDatasetVisibleImpl(chart, 0)).toBe(false);
  FFI.setDatasetVisibilityImpl(chart, 0, true);
  expect(FFI.isDatasetVisibleImpl(chart, 0)).toBe(true);
});

test("HideDataset: hideImpl entire dataset", () => {
  FFI.hideImpl(chart, 0, null);
});

test("ShowDataset: showImpl entire dataset", () => {
  FFI.showImpl(chart, 0, null);
});

test("ToggleDataVisibility: toggleDataVisibilityImpl", () => {
  FFI.toggleDataVisibilityImpl(chart, 0);
});

test("GetDataVisibility: getDataVisibilityImpl", () => {
  const visible = FFI.getDataVisibilityImpl(chart, 0);
  expect(typeof visible).toBe("boolean");
});

test("GetActiveElements: getActiveElementsImpl returns array", () => {
  const elements = FFI.getActiveElementsImpl(chart);
  expect(Array.isArray(elements)).toBe(true);
});

test("SetActiveElements: setActiveElementsImpl", () => {
  FFI.setActiveElementsImpl(chart, [{ datasetIndex: 0, index: 0 }]);
  const active = FFI.getActiveElementsImpl(chart);
  expect(active.length).toBe(1);
});

test("GetDatasetMeta: getDatasetMetaImpl returns object", () => {
  const meta = FFI.getDatasetMetaImpl(chart, 0);
  expect(meta).toBeDefined();
  expect(typeof meta).toBe("object");
});

test("GetVisibleDatasetCount: getVisibleDatasetCountImpl", () => {
  const count = FFI.getVisibleDatasetCountImpl(chart);
  expect(count).toBe(1);
});

test("GetSortedVisibleDatasetMetas: getSortedVisibleDatasetMetasImpl", () => {
  const metas = FFI.getSortedVisibleDatasetMetasImpl(chart);
  expect(Array.isArray(metas)).toBe(true);
  expect(metas.length).toBe(1);
});

test("IsPluginEnabled: isPluginEnabledImpl", () => {
  // 'legend' is a built-in plugin that should be enabled by default
  const enabled = FFI.isPluginEnabledImpl(chart, "legend");
  expect(typeof enabled).toBe("boolean");
});

test("IsPointInArea: isPointInAreaImpl", () => {
  const inside = FFI.isPointInAreaImpl(chart, { x: 200, y: 150 });
  expect(typeof inside).toBe("boolean");
});

test("GetChartContext: getChartContextImpl returns object with chart field", () => {
  const ctx = FFI.getChartContextImpl(chart);
  expect(ctx).toBeDefined();
  expect(ctx.chart).toBe(chart);
});

test("updateChartWithCallbacksImpl with mode", () => {
  const config = minimalBarConfig();
  config.data.datasets[0].data = [5, 10];
  FFI.updateChartWithCallbacksImpl(chart, config, {}, "none");
  expect(chart.data.datasets[0].data).toEqual([5, 10]);
});
