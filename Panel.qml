import QtQuick
import Quickshell
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The control panel. Always drawn in the system colors, with fixed chip shapes.
Panel {
  id: root
  moduleName: "io.github.soham3301.display-particles"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  property var store: null

  readonly property bool stormOn: store ? store.stormOn : false
  readonly property string ff: root.bar ? root.bar.fontFamily : Style.font.family

  function open() { root.controller.show() }
  function close() { root.controller.hide() }

  function switchPanel(direction) {
    if (root.bar && typeof root.bar.switchPanelFrom === "function")
      return root.bar.switchPanelFrom(root.hostWidget || root, direction)
    return false
  }

  function pick(key, value) { if (root.store) root.store.set(key, value) }

  // "now: Calm" while a section is on auto.
  function now(key, table, live) {
    if (!root.store || root.store[key] !== "auto") return ""
    var t = table[live]
    return t ? "now: " + t.name : ""
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.hostWidget || root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(300))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Column {
        id: content
        width: parent.width
        spacing: Style.space(10)

        Item {
          width: parent.width
          height: Style.space(24)

          Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Display Particles"
            color: Commons.Color.foreground
            font.family: root.ff
            font.pixelSize: Style.font.subtitle
            font.bold: true
          }

          Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: Style.space(38); height: Style.space(20); radius: height / 2
            color: root.stormOn ? Commons.Color.accent : Qt.rgba(Commons.Color.foreground.r, Commons.Color.foreground.g, Commons.Color.foreground.b, 0.28)

            Rectangle {
              width: parent.height - Style.space(6); height: width; radius: width / 2
              y: Style.space(3)
              x: root.stormOn ? parent.width - width - Style.space(3) : Style.space(3)
              color: root.stormOn ? Commons.Color.background : Commons.Color.foreground
              Behavior on x { NumberAnimation { duration: 150 } }
            }
            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: root.pick("stormOn", !root.stormOn)
            }
          }
        }

        OptionRow {
          width: parent.width; title: "Storm"; fontFamily: root.ff
          hint: root.now("stormType", Model.TYPES, root.store ? root.store.effStormType : "")
          options: Model.opts(Model.withAuto(Model.TYPE_ORDER), Model.TYPES, true)
          current: root.store ? root.store.stormType : ""
          onPicked: function(v) { root.pick("stormType", v) }
        }
        OptionRow {
          width: parent.width; title: "Power"; fontFamily: root.ff
          hint: root.now("power", Model.POWERS, root.store ? root.store.effPower : "")
          options: Model.opts(Model.withAuto(Model.POWER_ORDER), Model.POWERS, false)
          current: root.store ? root.store.power : ""
          onPicked: function(v) { root.pick("power", v) }
        }
        OptionRow {
          width: parent.width; title: "Particles"; fontFamily: root.ff
          hint: root.now("density", Model.DENSITIES, root.store ? root.store.effDensity : "")
          options: Model.opts(Model.withAuto(Model.DENSITY_ORDER), Model.DENSITIES, false)
          current: root.store ? root.store.density : ""
          onPicked: function(v) { root.pick("density", v) }
        }
        OptionRow {
          width: parent.width; title: "Particle size"; fontFamily: root.ff
          hint: root.now("particleSize", Model.SIZES, root.store ? root.store.effParticleSize : "")
          options: Model.opts(Model.withAuto(Model.SIZE_ORDER), Model.SIZES, false)
          current: root.store ? root.store.particleSize : ""
          onPicked: function(v) { root.pick("particleSize", v) }
        }
        OptionRow {
          width: parent.width; title: "Particle shape"; fontFamily: root.ff
          hint: root.now("shape", Model.SHAPES, root.store ? root.store.effShape : "")
          options: Model.opts(Model.withAuto(Model.SHAPE_ORDER), Model.SHAPES, false)
          current: root.store ? root.store.shape : ""
          onPicked: function(v) { root.pick("shape", v) }
        }
        OptionRow {
          width: parent.width; title: "Storm starts from"; fontFamily: root.ff
          options: Model.opts(Model.DIRECTION_ORDER, Model.DIRECTIONS, false)
          current: root.store ? root.store.direction : ""
          onPicked: function(v) { root.pick("direction", v) }
        }
      }
    }
  }
}
