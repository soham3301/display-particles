import QtQuick
import qs.Commons
import qs.Commons as Commons
import "Model.js" as Model

// The storm itself: wind, gust fronts, turbulence, spirals and the particles.
// Simulated in a left-to-right frame and mirrored when the storm starts top right.
// Storm type and shape changes fade out, switch, and fade back in. Particle count and size
// change gradually, so auto mode never makes the screen jump.
Item {
  id: root

  property var cfg: null    // Store: on/off and direction
  property var eff: null    // Auto: the values the storm should use now

  readonly property bool wanted: cfg ? (cfg.loaded && cfg.stormOn) : false
  readonly property bool mirrored: cfg ? cfg.direction === "right" : false
  readonly property string power: eff ? eff.power : "moderate"
  readonly property string density: eff ? eff.density : "avg"
  readonly property string particleSize: eff ? eff.particleSize : "medium"
  readonly property string wantType: eff ? eff.stormType : "system"
  readonly property string wantShape: eff ? eff.shape : "dot"

  // Applied after the fade, so colors and shapes never pop.
  property string stormType: "system"
  property string shape: "dot"
  property real swap: 1
  property bool ready: false

  readonly property real k: Math.max(0.6, Math.min(2, width / 1920))
  readonly property var typeInfo: Model.TYPES[stormType] || Model.TYPES.system
  readonly property var palette: typeInfo.colors || [Commons.Color.accent, Commons.Color.foreground, Commons.Color.accent]

  property int count: 0
  property int target: 0
  property var ps: []
  property var fronts: []
  property var vorts: []
  readonly property var sim: ({ t: 0, wind: 0, gust: 0, nextG: 2 })

  opacity: wanted ? 1 : 0
  Behavior on opacity { NumberAnimation { duration: 700 } }

  onWidthChanged: syncCount()
  onHeightChanged: syncCount()
  onDensityChanged: syncCount()
  onParticleSizeChanged: restyle()
  onPaletteChanged: restyle()
  onWantTypeChanged: requestSwap()
  onWantShapeChanged: requestSwap()
  Component.onCompleted: applyWanted()

  function applyWanted() {
    stormType = wantType
    shape = wantShape
    restyle()
  }

  function requestSwap() {
    if (!ready) { applyWanted(); return }
    if (wantType === stormType && wantShape === shape) return
    swapAnim.restart()
  }

  SequentialAnimation {
    id: swapAnim
    NumberAnimation { target: root; property: "swap"; to: 0; duration: 600; easing.type: Easing.InOutQuad }
    ScriptAction { script: root.applyWanted() }
    NumberAnimation { target: root; property: "swap"; to: 1; duration: 900; easing.type: Easing.InOutQuad }
  }

  function lv() { return Model.POWERS[power] || Model.POWERS.moderate }

  // Sets the particle count we are heading for. The first fill is immediate; later changes
  // add or remove particles a few at a time inside step().
  function syncCount() {
    if (width <= 0 || height <= 0) return
    var f = Math.max(0.5, Math.min(1.25, width * height / 504000))
    target = Math.round((Model.DENSITIES[density] || Model.DENSITIES.avg).count * f)
    if (ps.length === 0) {
      while (ps.length < target) ps.push(mk(true))
      count = ps.length
      Qt.callLater(function() { root.ready = true })
    }
  }

  function mk(scatter) {
    var r = Math.random
    var p = {
      x: 0, y: 0, vx: 0, vy: 0,
      z: 0.45 + r() * 0.55,
      w: r() < 0.3 ? 0 : (r() < 0.55 ? 1 : 2),   // 0 straight, 1 short wobble, 2 long swell
      k: 0.75 + r() * 0.5, fk: 0.7 + r() * 0.6,
      f: 6 + r() * 8, f2: 0.7 + r() * 1.1, ph: r() * 6.283,
      amp: 25 + r() * 45, amp2: 70 + r() * 120,
      sz0: 1.4 + r() * 2.6, a: 0.5 + r() * 0.5,
      rot: r() * 6.283, sp: (r() - 0.5) * 4, ci: Math.floor(r() * 3)
    }
    if (scatter) { p.x = r() * width; p.y = r() * height }
    else place(p)
    return p
  }

  // Re-enter from the top or the left edge, the left more often when the wind is strong.
  function place(p) {
    var L = lv()
    var pl = Math.min(0.7, sim.wind / (sim.wind + L.fall * k * 5 + 1))
    if (Math.random() < pl) { p.x = -10; p.y = Math.random() * height }
    else { p.x = Math.random() * width * 1.3 - width * 0.3; p.y = -10 }
  }

  function styleItem(i, d) {
    var p = ps[i]
    if (!p || !d) return
    var mul = (Model.SIZES[particleSize] || Model.SIZES.medium).mul
    d.sz = Math.max(0.9, p.sz0 * (0.55 + 0.45 * p.z) * mul * k)
    d.col = palette[p.ci % palette.length]
    d.opacity = p.a
    d.x = mirrored ? width - p.x : p.x
    d.y = p.y
  }

  function restyle() {
    for (var i = 0; i < ps.length; i++) styleItem(i, rep.itemAt(i))
  }

  function step(dt0) {
    var dt = Math.min(0.05, dt0), L = lv(), W = width, H = height, i, j
    sim.t += dt
    var t = sim.t

    // Move toward the wanted particle count a few at a time.
    if (ps.length !== target) {
      var diff = target - ps.length
      var n = Math.max(1, Math.ceil(Math.abs(diff) * dt * 1.2))
      if (diff > 0) { for (i = 0; i < n && ps.length < target; i++) ps.push(mk(false)) }
      else ps.length = Math.max(target, ps.length - n)
      count = ps.length
    }

    // Gusts: a global push, and sometimes a wind front that sweeps across the screen.
    if (t > sim.nextG) {
      sim.gust += L.amp * L.gust * k * (0.8 + Math.random())
      if (Math.random() < L.front)
        fronts.push({ pos: -0.15 * W, speed: W / (1.4 + Math.random() * 1.8), width: W * (0.1 + Math.random() * 0.12),
                      str: L.amp * L.gust * k * (0.8 + Math.random() * 0.9) })
      sim.nextG = t + L.gap[0] + Math.random() * (L.gap[1] - L.gap[0])
    }
    sim.gust *= Math.exp(-dt * 1.4)
    sim.wind = Math.max(L.base * 0.1 * k,
      (L.base * (1 + 0.2 * Math.sin(t * 0.3)) + L.amp * (0.5 * Math.sin(t * 0.8) + 0.3 * Math.sin(t * 2.1 + 1.3) + 0.2 * Math.sin(t * 4.7 + 0.4))) * k + sim.gust)
    var wind = sim.wind

    for (i = fronts.length - 1; i >= 0; i--) {
      fronts[i].pos += fronts[i].speed * dt
      if (fronts[i].pos > W + fronts[i].width * 2) fronts.splice(i, 1)
    }

    // Spirals: short-lived dust devils that drift with the wind.
    if (L.vmax > 0 && vorts.length < L.vmax && Math.random() < L.vort * dt) {
      var r0 = (90 + Math.random() * 130) * k
      vorts.push({ x: -r0 + Math.random() * W * 0.6, y: H * (0.15 + Math.random() * 0.75), r: r0,
                   s: (Math.random() < 0.5 ? -1 : 1) * (200 + Math.random() * 220) * k * L.vstr,
                   age: 0, life: 3 + Math.random() * 4, vy: (Math.random() - 0.5) * 30 * k, env: 0 })
    }
    for (i = vorts.length - 1; i >= 0; i--) {
      var v = vorts[i]
      v.age += dt
      v.x += wind * 0.45 * dt
      v.y += v.vy * dt
      v.env = Math.sin(Math.PI * Math.min(1, v.age / v.life))
      if (v.age > v.life || v.x > W + 2 * v.r) vorts.splice(i, 1)
    }

    var flick = !!typeInfo.flicker
    var isStreak = shape === "streak"
    var mir = mirrored

    for (i = 0; i < ps.length; i++) {
      var p = ps[i]
      var tx = wind * p.k * (0.55 + 0.45 * p.z)
      var ty = L.fall * k * p.z * p.fk

      // Per-particle waves: none, short wobble, or long swell with a little lift.
      if (p.w === 1) tx += Math.sin(t * p.f + p.ph) * p.amp * k * L.wave
      else if (p.w === 2) {
        tx += Math.sin(t * p.f2 + p.ph) * p.amp2 * k * L.wave
        ty += Math.cos(t * p.f2 * 0.9 + p.ph) * p.amp2 * 0.25 * k * L.wave
      }

      // Turbulence: a slowly moving noise field.
      if (L.turb > 0) {
        tx += Math.sin(p.y * 0.012 + t * 1.7 + p.ph) * Math.cos(p.x * 0.008 - t * 1.1) * L.turb * (50 * k + wind * 0.2)
        ty += Math.cos(p.x * 0.010 + t * 1.3 - p.ph) * Math.sin(p.y * 0.009 + t * 0.9) * L.turb * (35 * k + wind * 0.12)
      }

      // Wind fronts: a moving band of extra push with a slight updraft.
      for (j = 0; j < fronts.length; j++) {
        var u = (p.x - fronts[j].pos) / fronts[j].width
        var g = Math.exp(-u * u) * fronts[j].str
        tx += g
        ty -= g * 0.18
      }

      // Spirals: swirl around each dust devil, with a little inward pull.
      for (j = 0; j < vorts.length; j++) {
        var vt = vorts[j]
        var dx = p.x - vt.x, dy = p.y - vt.y
        var dd = Math.sqrt(dx * dx + dy * dy) + 0.001, q = dd / vt.r
        if (q < 4) {
          var m = q * Math.exp(1 - q) * vt.s * vt.env
          var pull = Math.exp(-q) * Math.abs(vt.s) * 0.25 * vt.env
          tx += (-dy / dd) * m - (dx / dd) * pull
          ty += (dx / dd) * m - (dy / dd) * pull
        }
      }

      p.vx += (tx - p.vx) * Math.min(1, dt * (1.2 + p.z * 2))
      p.vy += (ty - p.vy) * Math.min(1, dt * 3)
      p.x += p.vx * dt
      p.y += p.vy * dt
      p.rot += p.sp * dt * (0.4 + wind / (300 * k))

      // Nothing piles up: leaving the bottom or right edge means coming back in.
      if (p.y > H + 14 || p.x > W + 14 || p.x < -0.4 * W - 20 || p.y < -90) place(p)

      var d = rep.itemAt(i)
      if (!d) continue
      d.x = mir ? W - p.x : p.x
      d.y = p.y
      if (isStreak) {
        d.rotation = Math.atan2(p.vy, mir ? -p.vx : p.vx) * 57.2958
        d.len = d.sz * 2.5 + Math.sqrt(p.vx * p.vx + p.vy * p.vy) * 0.03
      } else {
        d.rotation = p.rot * 57.2958
      }
      if (flick) d.opacity = p.a * (0.6 + 0.4 * Math.sin(t * 9 + p.ph))
    }
  }

  FrameAnimation {
    running: root.opacity > 0.01 && root.count > 0
    onTriggered: root.step(frameTime)
  }

  readonly property Component shapeComp:
    shape === "streak" ? streakC : shape === "flake" ? flakeC : shape === "shard" ? shardC : shape === "pixel" ? pixelC : dotC

  // Each shape reads sz / col / len from the particle item (the Loader's parent).
  Component { id: dotC
    Rectangle {
      readonly property var d: parent ? parent.parent : null
      width: d ? d.sz : 1; height: width; radius: width / 2
      x: -width / 2; y: -height / 2
      color: d ? d.col : "white"; antialiasing: true
    }
  }
  Component { id: pixelC
    Rectangle {
      readonly property var d: parent ? parent.parent : null
      width: Math.max(1, Math.round(d ? d.sz : 1)); height: width
      x: -width / 2; y: -height / 2
      color: d ? d.col : "white"
    }
  }
  Component { id: streakC
    Rectangle {
      readonly property var d: parent ? parent.parent : null
      width: d ? d.len : 4; height: Math.max(1, (d ? d.sz : 1) * 0.45); radius: height / 2
      x: -width / 2; y: -height / 2
      color: d ? d.col : "white"; antialiasing: true
    }
  }
  Component { id: flakeC
    Item {
      id: fl
      readonly property var d: parent ? parent.parent : null
      Repeater {
        model: 3
        Rectangle {
          required property int index
          width: (fl.d ? fl.d.sz : 1) * 2.4; height: Math.max(1, (fl.d ? fl.d.sz : 1) * 0.2)
          x: -width / 2; y: -height / 2
          rotation: index * 60
          color: fl.d ? fl.d.col : "white"; antialiasing: true
        }
      }
    }
  }
  Component { id: shardC
    Item {
      id: sh
      readonly property var d: parent ? parent.parent : null
      transform: Scale { xScale: 1.7; yScale: 0.6 }
      Rectangle {
        width: sh.d ? sh.d.sz : 1; height: width
        x: -width / 2; y: -height / 2
        rotation: 45
        color: sh.d ? sh.d.col : "white"; antialiasing: true
      }
    }
  }

  Item {
    id: field
    anchors.fill: parent
    opacity: root.swap

    Repeater {
      id: rep
      model: root.count
      onItemAdded: function(index, item) { root.styleItem(index, item) }
      delegate: Item {
        property real sz: 2
        property color col: "white"
        property real len: 4
        width: 1
        height: 1
        Behavior on sz { enabled: root.ready; NumberAnimation { duration: 1500 } }
        Loader { sourceComponent: root.shapeComp }
      }
    }
  }
}
