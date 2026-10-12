.pragma library

// Single source of truth for every option, palette and physics preset.

var DEFAULTS = {
  stormOn: true, stormType: "system", power: "moderate", density: "avg",
  particleSize: "medium", shape: "dot", direction: "left"
}

var TYPE_ORDER = ["system", "sand", "snow", "ash", "fire", "leaves", "rain"]
var TYPES = {
  system: { name: "System", colors: null, ring: null },
  sand:   { name: "Sand",   colors: ["#c9a45c", "#b8934d", "#d6b878"], ring: "#c9a45c" },
  snow:   { name: "Snow",   colors: ["#eaf5ff", "#cfe6fa", "#dbeeff"], ring: "#cfe6fa" },
  ash:    { name: "Ash",    colors: ["#2b2b30", "#3d3d44", "#505058"], ring: "#74747e" },
  fire:   { name: "Fire",   colors: ["#ff3d1f", "#ff7a1a", "#ffb02e"], ring: "#ff6a1f", flicker: true },
  leaves: { name: "Leaves", colors: ["#6fa34a", "#8bbd4f", "#c0883a"], ring: "#8bbd4f" },
  rain:   { name: "Rain",   colors: ["#8fb4d6", "#a9c8e4"],            ring: "#8fb4d6" },
  auto:   { name: "Auto" }
}

// Speeds are px/s at 1920px width (the shell scales them to the screen).
// base/amp: mean wind and its swing. fall: fall speed. gust/gap: gust strength and seconds between gusts.
// wave: size of per-particle waves. turb: turbulence. front: chance a gust is a sweeping wind front.
// vort/vmax/vstr: spiral (dust devil) spawn rate per second, max at once, strength.
var POWER_ORDER = ["calm", "moderate", "intense"]
var POWERS = {
  calm:     { name: "Calm",     base: 24,  amp: 12,  fall: 20,  gust: 0.4, gap: [6, 12],  wave: 0.25, turb: 0,    front: 0,   vort: 0,    vmax: 0, vstr: 0 },
  moderate: { name: "Moderate", base: 130, amp: 85,  fall: 58,  gust: 1,   gap: [3, 7],   wave: 0.7,  turb: 0.35, front: 0.5, vort: 0.06, vmax: 1, vstr: 0.5 },
  intense:  { name: "Intense",  base: 340, amp: 240, fall: 115, gust: 1.6, gap: [1.4, 4], wave: 1.2,  turb: 1,    front: 1,   vort: 0.45, vmax: 3, vstr: 1 },
  auto:     { name: "Auto" }
}

var DENSITY_ORDER = ["min", "avg", "max"]
var DENSITIES = {
  min: { name: "Min", count: 90 }, avg: { name: "Avg", count: 260 }, max: { name: "Max", count: 600 },
  auto: { name: "Auto" }
}

var SIZE_ORDER = ["small", "medium", "large"]
var SIZES = {
  small: { name: "Small", mul: 0.5 }, medium: { name: "Medium", mul: 1 }, large: { name: "Large", mul: 1.9 },
  auto: { name: "Auto" }
}

var SHAPE_ORDER = ["dot", "streak", "flake", "shard", "pixel"]
var SHAPES = {
  dot: { name: "Dot" }, streak: { name: "Streak" }, flake: { name: "Flake" }, shard: { name: "Shard" }, pixel: { name: "Pixel" },
  auto: { name: "Auto" }
}

var DIRECTION_ORDER = ["left", "right"]
var DIRECTIONS = { left: { name: "Top left" }, right: { name: "Top right" } }

// The order a panel row shows: the real choices, then Auto.
function withAuto(order) { return order.concat(["auto"]) }

var OPTIONS = {
  stormType: withAuto(TYPE_ORDER), power: withAuto(POWER_ORDER), density: withAuto(DENSITY_ORDER),
  particleSize: withAuto(SIZE_ORDER), shape: withAuto(SHAPE_ORDER), direction: DIRECTION_ORDER
}

// Auto mode timing (minutes) and odds.
//  storm and shape: swap to a different one after a random 3 to 30 minutes.
//  power, particles, size: stay on the low level 60-70% of the time; of the rest, the middle level gets 60-70%.
var AUTO = { swapMin: 3, swapMax: 30, levelMin: 1.5, levelMax: 6, lowShare: [0.6, 0.7], midShare: [0.6, 0.7] }

// Build [{value, label, dot}] for the panel chips. dot: "accent" means the system accent.
function opts(order, table, withDot) {
  var out = []
  for (var i = 0; i < order.length; i++) {
    var k = order[i]
    var o = { value: k, label: table[k].name, dot: "" }
    if (withDot && k !== "auto") o.dot = table[k].ring || "accent"
    out.push(o)
  }
  return out
}
