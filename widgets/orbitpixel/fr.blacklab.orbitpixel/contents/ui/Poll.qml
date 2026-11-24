// Exécute une commande shell à intervalle régulier et émet sa sortie standard.
import QtQuick
import org.kde.plasma.plasma5support as P5Support

P5Support.DataSource {
    id: ds

    property string command: ""
    signal output(string text)

    engine: "executable"
    connectedSources: command !== "" ? [command] : []

    onNewData: (sourceName, data) => {
        ds.output(data["stdout"] ? String(data["stdout"]) : "")
    }
}
