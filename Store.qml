import QtQuick
import Quickshell
import Quickshell.Io
import "Model.js" as Model

// Settings shared by the overlay and the bar widget through small JSON files.
//  settings.json  what the user picked (may be "auto"); written by the panel
//  live.json      what auto mode is using right now; written by the overlay
// Every Store instance watches (and gently polls) both files, so the panel can talk to the
// overlay from a different QML scope without any IPC.
Item {
  id: root
  visible: false
  width: 0
  height: 0

  property bool loaded: false
  property bool stormOn: Model.DEFAULTS.stormOn
  property string stormType: Model.DEFAULTS.stormType
  property string power: Model.DEFAULTS.power
  property string density: Model.DEFAULTS.density
  property string particleSize: Model.DEFAULTS.particleSize
  property string shape: Model.DEFAULTS.shape
  property string direction: Model.DEFAULTS.direction

  // What auto mode is using right now (empty until the overlay has published it).
  property string liveStormType: ""
  property string livePower: ""
  property string liveDensity: ""
  property string liveParticleSize: ""
  property string liveShape: ""

  // What is actually showing: the pick, or the live auto value when the pick is "auto".
  readonly property string effStormType: stormType === "auto" ? (liveStormType || "system") : stormType
  readonly property string effPower: power === "auto" ? (livePower || "calm") : power
  readonly property string effDensity: density === "auto" ? (liveDensity || "min") : density
  readonly property string effParticleSize: particleSize === "auto" ? (liveParticleSize || "small") : particleSize
  readonly property string effShape: shape === "auto" ? (liveShape || "dot") : shape

  readonly property var keys: ["stormOn", "stormType", "power", "density", "particleSize", "shape", "direction"]
  readonly property string dir: (Quickshell.env("XDG_STATE_HOME") || ((Quickshell.env("HOME") || "") + "/.local/state")) + "/display-particles"
  property double holdUntil: 0

  function valid(key, value) {
    if (key === "stormOn") return typeof value === "boolean"
    var list = Model.OPTIONS[key]
    return !!list && list.indexOf(value) >= 0
  }

  function set(key, value) {
    if (!valid(key, value) || root[key] === value) return
    root[key] = value
    save()
  }

  function save() {
    var o = {}
    for (var i = 0; i < keys.length; i++) o[keys[i]] = root[keys[i]]
    holdUntil = Date.now() + 900   // ignore our own stale reads while the write lands
    fv.setText(JSON.stringify(o, null, 2) + "\n")
  }

  function applyText(txt) {
    if (Date.now() < holdUntil) return
    var o = null
    try { o = JSON.parse(txt) } catch (e) { return }
    if (!o || typeof o !== "object") return
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i]
      if (o[k] !== undefined && valid(k, o[k])) root[k] = o[k]
    }
  }

  // Overlay only: publish the values auto mode is using.
  function writeLive(o) {
    liveFv.setText(JSON.stringify(o) + "\n")
  }

  function applyLive(txt) {
    var o = null
    try { o = JSON.parse(txt) } catch (e) { return }
    if (!o || typeof o !== "object") return
    if (typeof o.stormType === "string") liveStormType = o.stormType
    if (typeof o.power === "string") livePower = o.power
    if (typeof o.density === "string") liveDensity = o.density
    if (typeof o.particleSize === "string") liveParticleSize = o.particleSize
    if (typeof o.shape === "string") liveShape = o.shape
  }

  FileView {
    id: fv
    path: root.dir + "/settings.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: { root.applyText(fv.text()); root.loaded = true }
    onLoadFailed: root.loaded = true   // first run: no file yet, use defaults
  }

  FileView {
    id: liveFv
    path: root.dir + "/live.json"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: root.applyLive(liveFv.text())
  }

  Timer {
    interval: 1500
    repeat: true
    running: true
    onTriggered: { fv.reload(); liveFv.reload() }
  }

  Component.onCompleted: Quickshell.execDetached(["mkdir", "-p", root.dir])
}
