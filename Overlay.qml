import QtQuick
import Quickshell
import Quickshell.Wayland

// Full-screen, click-through storm on every monitor.
Item {
  id: root

  // Injected by the shell.
  property var shell: null
  property string omarchyPath: ""
  property var manifest: null

  readonly property bool opened: store.stormOn

  // omarchy-shell shell summon <id> '{"stormType":"snow","power":"intense"}' sets any of the saved options.
  function open(payloadJson) {
    var p = {}
    try { p = JSON.parse(payloadJson || "{}") } catch (e) { p = {} }
    if (p.boot) return   // sent by the bar widget at login: keep the saved on/off state
    for (var i = 0; i < store.keys.length; i++) {
      var k = store.keys[i]
      if (p[k] !== undefined) store.set(k, p[k])
    }
    store.set("stormOn", true)
  }

  function close() {
    store.set("stormOn", false)
  }

  Store { id: store }
  Auto { id: auto; store: store }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: win
      required property var modelData
      screen: modelData

      visible: store.loaded && (store.stormOn || storm.opacity > 0.01)
      color: "transparent"
      anchors { top: true; bottom: true; left: true; right: true }
      exclusionMode: ExclusionMode.Ignore
      mask: Region {}   // empty input region: every click goes through to the apps below

      WlrLayershell.namespace: "display-particles"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

      Storm {
        id: storm
        anchors.fill: parent
        cfg: store
        eff: auto
      }
    }
  }
}
