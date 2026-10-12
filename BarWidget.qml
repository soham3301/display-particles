import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The bar icon: a small light. It blinks slowly and at random in the system color,
// turns red and blinks fast in Intense power, and goes grey and still when the storm is off.
// Left click opens the panel, right click starts or stops the storm.
BarWidget {
  id: root
  moduleName: "io.github.soham3301.display-particles"

  readonly property string pluginId: "io.github.soham3301.display-particles"
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  readonly property bool on: store.loaded && store.stormOn
  readonly property bool intense: store.effPower === "intense"   // follows auto mode too
  readonly property color lightColor: !on ? Commons.Color.foreground : (intense ? "#ff2a2a" : Commons.Color.accent)
  readonly property int box: (root.bar && root.bar.barSize) ? root.bar.barSize : 26

  property bool lit: true
  property int fadeMs: 1200

  // The shell may also call open(payloadJson); the "boot" summon below is not a request to show the panel.
  function open(payloadJson) {
    if (payloadJson && String(payloadJson).indexOf("boot") >= 0) return
    if (panelLoader.item) panelLoader.item.open()
  }
  function close() { if (panelLoader.item) panelLoader.item.close() }
  function toggle() { if (panelLoader.item) panelLoader.item.toggle() }
  function closeForPopoutSwitch() { if (panelLoader.item) panelLoader.item.closeForPopoutSwitch() }

  function injectPanel() {
    if (!panelLoader.item) return
    panelLoader.item.bar = root.bar
    panelLoader.item.anchorItem = lightBox
    panelLoader.item.hostWidget = root
    panelLoader.item.store = store
  }

  implicitWidth: box
  implicitHeight: box
  onBarChanged: injectPanel()
  onOnChanged: { lit = true; blink.interval = 1200 }

  Store { id: store }

  // Make sure the overlay is loaded after login. "boot" keeps the saved on/off state.
  Timer {
    interval: 1500
    running: true
    onTriggered: Quickshell.execDetached(["omarchy-shell", "shell", "summon", root.pluginId, "{\"boot\":true}"])
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onStatusChanged: if (status === Loader.Error) console.warn("[display-particles] Panel.qml failed to load")
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }

  Item {
    id: lightBox
    anchors.fill: parent

    // Soft glow behind the light.
    Rectangle {
      anchors.centerIn: parent
      width: dot.width * (root.intense ? 3 : 2.4)
      height: width
      radius: width / 2
      color: root.lightColor
      opacity: root.on ? dot.opacity * 0.25 : 0
      Behavior on color { ColorAnimation { duration: 600 } }
    }

    Rectangle {
      id: dot
      anchors.centerIn: parent
      width: Math.max(6, Math.round(root.box * 0.3))
      height: width
      radius: width / 2
      color: root.lightColor
      opacity: !root.on ? 0.4 : (root.lit ? 1 : 0.1)
      Behavior on color { ColorAnimation { duration: 900 } }
      Behavior on opacity { NumberAnimation { duration: root.on ? root.fadeMs : 900; easing.type: Easing.InOutSine } }
    }
  }

  // Slow and random normally, fast and regular in Intense.
  Timer {
    id: blink
    interval: 1200
    repeat: true
    running: root.on
    onTriggered: {
      root.lit = !root.lit
      if (root.intense) {
        root.fadeMs = 60
        interval = 140
      } else {
        root.fadeMs = 900 + Math.random() * 1300
        interval = root.fadeMs + (root.lit ? 300 + Math.random() * 1200 : 500 + Math.random() * 2500)
      }
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton
    cursorShape: Qt.PointingHandCursor
    onClicked: function(mouse) {
      if (mouse.button === Qt.RightButton) store.set("stormOn", !store.stormOn)
      else root.toggle()
    }
  }
}
