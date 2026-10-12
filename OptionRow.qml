import QtQuick
import qs.Commons
import qs.Commons as Commons

// A titled row of single-choice chips for the panel.
Item {
  id: row

  property string title: ""
  property string hint: ""        // small note next to the title, e.g. what auto mode is using
  property var options: []        // [{ value, label, dot }]
  property string current: ""
  property string fontFamily: Style.font.family
  signal picked(string value)

  implicitHeight: col.implicitHeight
  height: implicitHeight

  function fade(c, a) { return Qt.rgba(c.r, c.g, c.b, a) }

  Column {
    id: col
    width: parent.width
    spacing: Style.space(4)

    Row {
      spacing: Style.space(8)
      Text {
        text: row.title
        color: row.fade(Commons.Color.foreground, 0.65)
        font.family: row.fontFamily
        font.pixelSize: Style.font.caption
      }
      Text {
        visible: row.hint !== ""
        text: row.hint
        color: row.fade(Commons.Color.accent, 0.9)
        font.family: row.fontFamily
        font.pixelSize: Style.font.caption
      }
    }

    Flow {
      width: parent.width
      spacing: Style.space(4)

      Repeater {
        model: row.options
        delegate: Rectangle {
          id: chip
          required property var modelData
          readonly property bool sel: modelData.value === row.current

          width: content.implicitWidth + Style.space(16)
          height: Style.space(26)
          radius: Style.space(6)
          color: sel ? Commons.Color.accent : "transparent"
          border.width: 1
          border.color: sel ? Commons.Color.accent : row.fade(Commons.Color.foreground, 0.28)

          Row {
            id: content
            anchors.centerIn: parent
            spacing: Style.space(5)

            Rectangle {
              visible: !!chip.modelData.dot
              width: Style.space(7); height: width; radius: width / 2
              anchors.verticalCenter: parent.verticalCenter
              color: chip.modelData.dot === "accent" ? Commons.Color.accent : (chip.modelData.dot || "transparent")
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: chip.modelData.label
              color: chip.sel ? Commons.Color.background : Commons.Color.foreground
              font.family: row.fontFamily
              font.pixelSize: Style.font.bodySmall
            }
          }

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: row.picked(chip.modelData.value)
          }
        }
      }
    }
  }
}
