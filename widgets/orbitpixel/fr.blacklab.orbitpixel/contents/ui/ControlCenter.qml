// Control Center : ajouter / retirer des modules, couleur d'accent, transparence, disques, ville météo.
// Les réglages visuels sont écrits dans ~/.config/orbitpixelrc et suivis par tous les modules.
import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts

Rectangle {
    id: cc

    property var theme
    property var cfg
    property string modId: ""

    readonly property var shared: theme ? theme.shared : ({})
    readonly property string ctl: decodeURIComponent(Qt.resolvedUrl("../scripts/orbit-ctl.sh").toString().replace(/^file:\/\//, ""))

    property var active: ({})
    property var disks: []
    property real lastAction: 0
    property string status: ""
    property var cityResults: []
    property bool searching: false

    readonly property var catalog: [
        { id: "calendar", name: "CALENDRIER" },
        { id: "clock-h", name: "HEURES" },
        { id: "clock-m", name: "MINUTES" },
        { id: "clock-s", name: "SECONDES" },
        { id: "cpu", name: "CPU" },
        { id: "ram", name: "RAM" },
        { id: "gpu", name: "GPU" },
        { id: "network", name: "RESEAU" },
        { id: "ip", name: "SYSTEME / IP" },
        { id: "energy", name: "ENERGIE" },
        { id: "volume", name: "VOLUME" },
        { id: "weather", name: "METEO" },
        { id: "media", name: "MEDIA" },
        { id: "media-alt", name: "MEDIA (ALT)" },
        { id: "micro", name: "MICRO" },
        { id: "micro-alt", name: "MICRO (ALT)" }
    ]
    readonly property var swatches: ["#ff1654", "#ff0000", "#ff8000", "#ffff00", "#00ff00", "#008080", "#0080ff", "#8000ff", "#ffffff"]
    readonly property string curAccent: (shared.accent || (cfg ? cfg.accent : "#ff1654")).toLowerCase()
    readonly property int curAlpha: shared.bgAlpha !== undefined ? parseInt(shared.bgAlpha) : (cfg ? cfg.bgAlpha : 190)

    color: Qt.rgba(10 / 255, 10 / 255, 10 / 255, 0.97)
    radius: 8
    border.width: 1
    border.color: theme ? theme.border : "#333333"
    implicitWidth: 560
    implicitHeight: 640

    // ---------- actions ----------
    function q(s) { return "'" + String(s).replace(/'/g, "") + "'" }
    function validMount(s) { return /^[A-Za-z0-9._\/ -]+$/.test(s) }
    function run(args) { runner.run("sh " + q(ctl) + " " + args) }
    function setShared(k, v) {
        runner.run("kwriteconfig6 --file orbitpixelrc --group General --key " + k + " " + q(v))
    }

    function markActive(id, on) {
        var a = Object.assign({}, active)
        if (on) a[id] = true
        else delete a[id]
        active = a
        lastAction = Date.now()
    }
    function addModule(id) { run("add " + id); markActive(id, true); status = "" }
    function removeModule(id) { run("remove " + id); markActive(id, false); status = "" }

    function addDisk(mnt) {
        mnt = mnt.trim()
        if (!validMount(mnt)) {
            status = "Point de montage invalide (lettres, chiffres, . _ / - et espaces)"
            return
        }
        run("add disk " + q(mnt))
        if (disks.indexOf(mnt) < 0)
            disks = disks.concat([mnt])
        lastAction = Date.now()
        status = ""
    }
    function removeDisk(mnt) {
        run("remove disk " + q(mnt))
        disks = disks.filter(function (m) { return m !== mnt })
        lastAction = Date.now()
    }

    function parseList(text) {
        // Plasma n'écrit sa config qu'avec quelques secondes de retard : on garde l'état optimiste
        if (Date.now() - lastAction < 12000)
            return
        var a = {}, d = []
        text.split("\n").forEach(function (l) {
            l = l.trim()
            if (l === "") return
            if (l.indexOf("disk|") === 0) { d.push(l.slice(5)); a.disk = true }
            else a[l] = true
        })
        active = a
        disks = d
    }

    function searchCity(name) {
        name = name.trim()
        if (name === "")
            return
        searching = true
        cityResults = []
        status = ""
        var x = new XMLHttpRequest()
        x.onreadystatechange = function () {
            if (x.readyState !== XMLHttpRequest.DONE)
                return
            searching = false
            if (x.status !== 200) {
                status = "Recherche impossible (réseau ?)"
                return
            }
            try {
                cityResults = JSON.parse(x.responseText).results || []
            } catch (e) {
                cityResults = []
            }
            if (cityResults.length === 0)
                status = "Aucune ville trouvée"
        }
        x.open("GET", "https://geocoding-api.open-meteo.com/v1/search?count=6&language=fr&format=json&name=" + encodeURIComponent(name))
        x.send()
    }

    function pickCity(r) {
        setShared("latitude", r.latitude)
        setShared("longitude", r.longitude)
        setShared("city", r.name)
        cityResults = []
        status = "Ville choisie : " + r.name
    }

    Runner {
        id: runner
        onDone: (code, err) => {
            if (code !== 0)
                cc.status = "Erreur : " + err.trim().slice(0, 140)
        }
    }

    Poll {
        command: cc.visible ? "sh " + cc.q(cc.ctl) + " list" : ""
        interval: 3000
        onOutput: (text) => cc.parseList(text)
    }

    // ---------- interface ----------
    QQC2.ScrollView {
        anchors.fill: parent
        anchors.margins: 16
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: cc.width - 48
            spacing: 12

            ColumnLayout {
                spacing: 2
                OLabel { theme: cc.theme; pt: 16; text: "ORBIT PIXEL // CONTROL CENTER" }
                OLabel { theme: cc.theme; pt: 7; muted: true; text: "// BY D-GOTH // BLACK-LAB.FR" }
                Rectangle { Layout.topMargin: 4; Layout.preferredWidth: 44; Layout.preferredHeight: 2; color: cc.theme.accent }
            }

            // ----- modules -----
            OLabel { theme: cc.theme; pt: 9; accent: true; text: "// MODULES" }
            OLabel {
                Layout.fillWidth: true
                theme: cc.theme
                plain: true
                pt: 9
                muted: true
                wrapMode: Text.WordWrap
                text: "+ ajoute le module sur le bureau, ✕ le retire. Pour le déplacer : clic droit sur le bureau, « Entrer en mode édition »."
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: 8
                rowSpacing: 6

                Repeater {
                    model: cc.catalog
                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        radius: 4
                        color: Qt.rgba(1, 1, 1, 0.04)
                        border.width: 1
                        border.color: cc.active[modelData.id] ? cc.theme.accent : cc.theme.border

                        OLabel {
                            x: 10
                            anchors.verticalCenter: parent.verticalCenter
                            theme: cc.theme
                            pt: 9
                            text: card.modelData.name
                        }
                        Row {
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            OButton { theme: cc.theme; label: "+"; highlighted: !!cc.active[card.modelData.id]; onClicked: cc.addModule(card.modelData.id) }
                            OButton { theme: cc.theme; label: "✕"; onClicked: cc.removeModule(card.modelData.id) }
                        }
                    }
                }
            }

            // ----- disques -----
            OLabel { theme: cc.theme; pt: 9; accent: true; text: "// DISQUES" }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                QQC2.TextField {
                    id: mountField
                    Layout.fillWidth: true
                    placeholderText: "Point de montage : /home, /media/…"
                    onAccepted: cc.addDisk(text)
                }
                OButton { theme: cc.theme; label: "+ DISQUE"; onClicked: cc.addDisk(mountField.text) }
            }
            Repeater {
                model: cc.disks
                delegate: RowLayout {
                    id: diskRow
                    required property string modelData
                    Layout.fillWidth: true
                    OLabel { Layout.fillWidth: true; theme: cc.theme; plain: true; pt: 10; text: "Disque  " + diskRow.modelData }
                    OButton { theme: cc.theme; label: "✕"; onClicked: cc.removeDisk(diskRow.modelData) }
                }
            }

            // ----- météo -----
            OLabel { theme: cc.theme; pt: 9; accent: true; text: "// METEO" }
            OLabel {
                theme: cc.theme
                plain: true
                pt: 10
                text: "Ville actuelle : " + (cc.shared.city ? cc.shared.city : "aucune")
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                QQC2.TextField {
                    id: cityField
                    Layout.fillWidth: true
                    placeholderText: "Chercher une ville…"
                    onAccepted: cc.searchCity(text)
                }
                OButton { theme: cc.theme; label: cc.searching ? "…" : "CHERCHER"; onClicked: cc.searchCity(cityField.text) }
            }
            Repeater {
                model: cc.cityResults
                delegate: OButton {
                    required property var modelData
                    Layout.fillWidth: true
                    theme: cc.theme
                    label: modelData.name + (modelData.admin1 ? " · " + modelData.admin1 : "") + (modelData.country ? " · " + modelData.country : "")
                    onClicked: cc.pickCity(modelData)
                }
            }

            // ----- apparence -----
            OLabel { theme: cc.theme; pt: 9; accent: true; text: "// APPARENCE" }
            RowLayout {
                spacing: 8
                Repeater {
                    model: cc.swatches
                    delegate: Rectangle {
                        id: sw
                        required property string modelData
                        implicitWidth: 28
                        implicitHeight: 28
                        radius: 14
                        color: modelData
                        border.width: cc.curAccent === modelData ? 3 : 1
                        border.color: cc.curAccent === modelData ? "white" : cc.theme.border
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: cc.setShared("accent", sw.modelData)
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                OLabel { theme: cc.theme; plain: true; pt: 10; text: "Accent (hex)" }
                QQC2.TextField { id: hexField; implicitWidth: 110; text: cc.curAccent }
                OButton {
                    theme: cc.theme
                    label: "OK"
                    onClicked: {
                        if (/^#[0-9a-fA-F]{6}$/.test(hexField.text))
                            cc.setShared("accent", hexField.text)
                        else
                            cc.status = "Format attendu : #rrggbb"
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                OLabel { theme: cc.theme; plain: true; pt: 10; text: "Transparence du fond" }
                QQC2.Slider {
                    id: alphaSlider
                    Layout.fillWidth: true
                    from: 0
                    to: 255
                    stepSize: 5
                    value: cc.curAlpha
                    onPressedChanged: {
                        if (!pressed)
                            cc.setShared("bgAlpha", Math.round(value))
                    }
                }
                OLabel { theme: cc.theme; plain: true; pt: 10; muted: true; text: Math.round(alphaSlider.value) + " / 255" }
            }

            OLabel {
                Layout.fillWidth: true
                visible: cc.status !== ""
                theme: cc.theme
                plain: true
                pt: 9
                accent: true
                wrapMode: Text.WordWrap
                text: cc.status
            }
            OLabel {
                Layout.fillWidth: true
                theme: cc.theme
                plain: true
                pt: 8
                muted: true
                wrapMode: Text.WordWrap
                text: "Couleur, transparence et ville sont partagées par tous les modules (fichier ~/.config/orbitpixelrc). Météo : données Open-Meteo.com (CC BY 4.0)."
            }
        }
    }
}
