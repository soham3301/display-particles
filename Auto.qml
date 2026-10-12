import QtQuick
import "Model.js" as Model

// Auto mode. Turns each "auto" pick into a real value and keeps changing it.
//  Storm and shape: switch to a different one after a random 3 to 30 minutes.
//  Power, particles, size: stay on the low level most of the time, with the middle level
//  next and the high level rarely.
// Every section has its own timer, so nothing is synchronized.
Item {
  id: root
  visible: false
  width: 0
  height: 0

  property var store: null
  readonly property bool going: store ? (store.loaded && store.stormOn) : false

  // The current auto choices (used only while that section is set to "auto").
  property string autoType: "system"
  property string autoShape: "dot"
  property string autoPower: "calm"
  property string autoDensity: "min"
  property string autoSize: "small"

  // What the storm should use right now.
  readonly property string stormType: (store && store.stormType !== "auto") ? store.stormType : autoType
  readonly property string shape: (store && store.shape !== "auto") ? store.shape : autoShape
  readonly property string power: (store && store.power !== "auto") ? store.power : autoPower
  readonly property string density: (store && store.density !== "auto") ? store.density : autoDensity
  readonly property string particleSize: (store && store.particleSize !== "auto") ? store.particleSize : autoSize

  function rnd(a, b) { return a + Math.random() * (b - a) }
  function ms(minMinutes, maxMinutes) { return Math.round(rnd(minMinutes, maxMinutes) * 60000) }

  // A different item from the list than the current one.
  function other(list, current) {
    var c = []
    for (var i = 0; i < list.length; i++) if (list[i] !== current) c.push(list[i])
    return c[Math.floor(Math.random() * c.length)]
  }

  // order = [low, middle, high]. Low gets 60-70%, middle gets 60-70% of the rest, high gets what is left.
  function weighted(order) {
    var low = rnd(Model.AUTO.lowShare[0], Model.AUTO.lowShare[1])
    var mid = (1 - low) * rnd(Model.AUTO.midShare[0], Model.AUTO.midShare[1])
    var r = Math.random()
    if (r < low) return order[0]
    if (r < low + mid) return order[1]
    return order[2]
  }

  Timer {
    id: typeTimer
    interval: root.ms(Model.AUTO.swapMin, Model.AUTO.swapMax)
    repeat: true
    running: root.going && root.store.stormType === "auto"
    onTriggered: { root.autoType = root.other(Model.TYPE_ORDER, root.autoType); interval = root.ms(Model.AUTO.swapMin, Model.AUTO.swapMax) }
  }
  Timer {
    id: shapeTimer
    interval: root.ms(Model.AUTO.swapMin, Model.AUTO.swapMax)
    repeat: true
    running: root.going && root.store.shape === "auto"
    onTriggered: { root.autoShape = root.other(Model.SHAPE_ORDER, root.autoShape); interval = root.ms(Model.AUTO.swapMin, Model.AUTO.swapMax) }
  }
  Timer {
    id: powerTimer
    interval: root.ms(Model.AUTO.levelMin, Model.AUTO.levelMax)
    repeat: true
    running: root.going && root.store.power === "auto"
    onTriggered: { root.autoPower = root.weighted(Model.POWER_ORDER); interval = root.ms(Model.AUTO.levelMin, Model.AUTO.levelMax) }
  }
  Timer {
    id: densityTimer
    interval: root.ms(Model.AUTO.levelMin, Model.AUTO.levelMax)
    repeat: true
    running: root.going && root.store.density === "auto"
    onTriggered: { root.autoDensity = root.weighted(Model.DENSITY_ORDER); interval = root.ms(Model.AUTO.levelMin, Model.AUTO.levelMax) }
  }
  Timer {
    id: sizeTimer
    interval: root.ms(Model.AUTO.levelMin, Model.AUTO.levelMax)
    repeat: true
    running: root.going && root.store.particleSize === "auto"
    onTriggered: { root.autoSize = root.weighted(Model.SIZE_ORDER); interval = root.ms(Model.AUTO.levelMin, Model.AUTO.levelMax) }
  }

  // Tell the bar widget what is showing, so its light and panel hints can follow auto mode.
  Timer {
    id: publish
    interval: 250
    onTriggered: if (root.store) root.store.writeLive({
      stormType: root.stormType, power: root.power, density: root.density,
      particleSize: root.particleSize, shape: root.shape
    })
  }
  onStormTypeChanged: publish.restart()
  onShapeChanged: publish.restart()
  onPowerChanged: publish.restart()
  onDensityChanged: publish.restart()
  onParticleSizeChanged: publish.restart()

  // Start every session from a fresh random pick.
  Component.onCompleted: {
    autoType = Model.TYPE_ORDER[Math.floor(Math.random() * Model.TYPE_ORDER.length)]
    autoShape = Model.SHAPE_ORDER[Math.floor(Math.random() * Model.SHAPE_ORDER.length)]
    autoPower = weighted(Model.POWER_ORDER)
    autoDensity = weighted(Model.DENSITY_ORDER)
    autoSize = weighted(Model.SIZE_ORDER)
    publish.restart()
  }
}
