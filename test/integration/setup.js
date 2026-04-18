// Shared setup for FFI integration tests. Called once at the top of each
// integration test file before importing anything from src/Chartjs/FFI.js.
//
// What it does:
// 1. Spins up JSDOM to provide document, window, HTMLCanvasElement, etc.
// 2. Installs the canvas-mock so HTMLCanvasElement.getContext("2d") returns
//    a stubbed 2D context Chart.js can use without rendering.
// 3. Copies the DOM globals onto globalThis so Chart.js's internal checks
//    (e.g. `typeof document !== "undefined"`) succeed.
//
// After this module runs, `new Chart(canvasElement, config)` works in node.

import { JSDOM } from "jsdom";
import { installCanvasMock } from "./canvas-mock.js";

const dom = new JSDOM(
  '<!DOCTYPE html><html><body><div id="root"></div></body></html>',
  { url: "http://localhost/", pretendToBeVisual: true },
);

const { window } = dom;
installCanvasMock(window);

// Expose DOM globals to Chart.js and any downstream consumers. Chart.js reads
// `document`, `window`, and some element constructors at module load time.
globalThis.window = window;
globalThis.document = window.document;
globalThis.HTMLCanvasElement = window.HTMLCanvasElement;
globalThis.HTMLElement = window.HTMLElement;
globalThis.Element = window.Element;
globalThis.Node = window.Node;
globalThis.Event = window.Event;
globalThis.MouseEvent = window.MouseEvent;
globalThis.ResizeObserver = class {
  observe() {}
  unobserve() {}
  disconnect() {}
};
// requestAnimationFrame is used by Chart.js's animation loop
if (!globalThis.requestAnimationFrame) {
  globalThis.requestAnimationFrame = (cb) => setTimeout(cb, 16);
  globalThis.cancelAnimationFrame = (id) => clearTimeout(id);
}

// Helper: create a detached canvas element of a given size ready for Chart.js
export function makeCanvas(width = 400, height = 300) {
  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  document.getElementById("root").appendChild(canvas);
  return canvas;
}

// Helper: minimum viable chart config — bar chart with two labels and one
// dataset. Enough for every FFI method in #15 to execute without error.
export function minimalBarConfig() {
  return {
    type: "bar",
    data: {
      labels: ["A", "B"],
      datasets: [{ label: "demo", data: [1, 2] }],
    },
    options: {
      responsive: false,
      animation: false,
      events: [],
    },
  };
}
