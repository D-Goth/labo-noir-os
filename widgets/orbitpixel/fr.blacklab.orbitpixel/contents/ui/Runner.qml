// Lance une commande une seule fois (actions : volume, muet, Control Center…).
import QtQuick
import org.kde.plasma.plasma5support as P5Support

P5Support.DataSource {
    id: r

    property int seq: 0

    signal done(int exitCode, string err)

    engine: "executable"

    onNewData: (sourceName, data) => {
        r.disconnectSource(sourceName)
        var code = data["exit code"] !== undefined ? Number(data["exit code"]) : 0
        r.done(code, data["stderr"] ? String(data["stderr"]) : "")
    }

    // le commentaire final rend chaque commande unique (plusieurs molettes d'affilée)
    function run(cmd) {
        seq += 1
        connectSource(cmd + " #" + seq)
    }
}
