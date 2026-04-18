// Minimal HTMLCanvasElement / CanvasRenderingContext2D mock sufficient to let
// Chart.js 4.x instantiate and run its instance methods without rendering. Not
// a full canvas implementation — just enough to satisfy the method/property
// lookups Chart.js performs during construction, update, and event handling.
//
// Used by test/integration/ffi.test.js in place of the `canvas` npm package
// (which has native deps). If Chart.js starts needing more methods, add them
// here.

// Mock 2D context — every method is a no-op, every getter returns a sane
// default that Chart.js can use without crashing.
function createMock2DContext(canvas) {
  const ctx = {
    canvas,
    // Transform / state
    save: () => {},
    restore: () => {},
    translate: () => {},
    rotate: () => {},
    scale: () => {},
    transform: () => {},
    setTransform: () => {},
    resetTransform: () => {},
    getTransform: () => ({ a: 1, b: 0, c: 0, d: 1, e: 0, f: 0 }),
    // Paths
    beginPath: () => {},
    closePath: () => {},
    moveTo: () => {},
    lineTo: () => {},
    bezierCurveTo: () => {},
    quadraticCurveTo: () => {},
    arc: () => {},
    arcTo: () => {},
    ellipse: () => {},
    rect: () => {},
    roundRect: () => {},
    // Drawing
    fill: () => {},
    stroke: () => {},
    clearRect: () => {},
    fillRect: () => {},
    strokeRect: () => {},
    fillText: () => {},
    strokeText: () => {},
    drawImage: () => {},
    // Clipping
    clip: () => {},
    // Measurement — Chart.js actually reads the return value
    measureText: (text) => ({
      width: (text || "").length * 6,
      actualBoundingBoxAscent: 8,
      actualBoundingBoxDescent: 2,
      actualBoundingBoxLeft: 0,
      actualBoundingBoxRight: (text || "").length * 6,
      fontBoundingBoxAscent: 8,
      fontBoundingBoxDescent: 2,
    }),
    // Gradients / patterns — return plain objects that Chart.js can assign
    // to strokeStyle/fillStyle without type-checking
    createLinearGradient: () => ({ addColorStop: () => {} }),
    createRadialGradient: () => ({ addColorStop: () => {} }),
    createPattern: () => ({}),
    // Image data
    createImageData: (w, h) => ({
      data: new Uint8ClampedArray((w || 1) * (h || 1) * 4),
      width: w || 1,
      height: h || 1,
    }),
    getImageData: (x, y, w, h) => ({
      data: new Uint8ClampedArray((w || 1) * (h || 1) * 4),
      width: w || 1,
      height: h || 1,
    }),
    putImageData: () => {},
    // Line dash (Chart.js queries these)
    setLineDash: () => {},
    getLineDash: () => [],
    // Pixel inclusion (Chart.js uses this for hit testing)
    isPointInPath: () => false,
    isPointInStroke: () => false,
    // Properties — Chart.js reads and writes all of these
    fillStyle: "#000",
    strokeStyle: "#000",
    globalAlpha: 1,
    lineWidth: 1,
    lineCap: "butt",
    lineJoin: "miter",
    miterLimit: 10,
    lineDashOffset: 0,
    shadowBlur: 0,
    shadowColor: "rgba(0,0,0,0)",
    shadowOffsetX: 0,
    shadowOffsetY: 0,
    font: "10px sans-serif",
    textAlign: "start",
    textBaseline: "alphabetic",
    direction: "inherit",
    imageSmoothingEnabled: true,
    imageSmoothingQuality: "low",
    globalCompositeOperation: "source-over",
    filter: "none",
  };
  return ctx;
}

// Install a getContext implementation on JSDOM's HTMLCanvasElement prototype.
// JSDOM ships the element but not the 2D context — getContext returns null by
// default, which makes Chart.js crash during construction.
export function installCanvasMock(window) {
  const HTMLCanvasElement = window.HTMLCanvasElement;
  // Cache per-canvas so consecutive getContext calls return the same ctx
  const contextCache = new WeakMap();

  HTMLCanvasElement.prototype.getContext = function getContext(type) {
    if (type !== "2d") return null;
    let ctx = contextCache.get(this);
    if (!ctx) {
      ctx = createMock2DContext(this);
      contextCache.set(this, ctx);
    }
    return ctx;
  };

  // Chart.js also calls these on the canvas element itself
  HTMLCanvasElement.prototype.toDataURL = function toDataURL() {
    return "data:image/png;base64,";
  };

  // addEventListener exists on JSDOM elements already, no need to mock
}
