pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Mpris
import qs.services
import qs.modules.common

Item {
    id: root

    readonly property MprisPlayer player: MprisController.activePlayer
    readonly property bool ytMusicEnabled: Config.options?.sidebar?.ytmusic?.enable ?? false
    readonly property bool isYtMusicActive: root._isYtMusicMpv(root.player)
    readonly property string _fallbackArtUrl: root.player?.trackArtUrl ?? ""
    readonly property string sourceUrl: root.isYtMusicActive && YtMusic.currentThumbnail
        ? YtMusic.currentThumbnail : root._fallbackArtUrl
    readonly property string title: root.isYtMusicActive && YtMusic.currentTitle
        ? YtMusic.currentTitle : (root.player?.trackTitle ?? "")
    readonly property string artist: root.isYtMusicActive && YtMusic.currentArtist
        ? YtMusic.currentArtist : (root.player?.trackArtist ?? "")
    readonly property string album: root.player?.trackAlbum ?? ""
    readonly property bool ready: artworkResolver.ready
    readonly property string displaySource: artworkResolver.displaySource
    readonly property string cacheDirectory: Directories.coverArt

    function _isYtMusicMpv(player): bool {
        if (!root.ytMusicEnabled || !player)
            return false;
        if (YtMusic.mpvPlayer && player === YtMusic.mpvPlayer)
            return true;
        const id = (player.identity ?? "").toLowerCase();
        const entry = (player.desktopEntry ?? "").toLowerCase();
        const isMpv = id === "mpv" || id.includes("mpv") || entry === "mpv" || entry.includes("mpv");
        if (!isMpv)
            return false;
        const trackUrl = player.metadata?.["xesam:url"] ?? "";
        return trackUrl.includes("youtube.com") || trackUrl.includes("youtu.be");
    }

    function refresh(): void {
        artworkResolver.refresh();
    }

    Connections {
        target: root.player

        function onTrackArtUrlChanged(): void {
            if (!root.isYtMusicActive)
                Qt.callLater(root.refresh);
        }

        function onTrackTitleChanged(): void {
            Qt.callLater(root.refresh);
        }

        function onTrackArtistChanged(): void {
            Qt.callLater(root.refresh);
        }

        function onTrackAlbumChanged(): void {
            Qt.callLater(root.refresh);
        }
    }

    Connections {
        target: YtMusic

        function onCurrentThumbnailChanged(): void {
            if (root.isYtMusicActive)
                Qt.callLater(root.refresh);
        }

        function onCurrentTitleChanged(): void {
            if (root.isYtMusicActive)
                Qt.callLater(root.refresh);
        }

        function onCurrentArtistChanged(): void {
            if (root.isYtMusicActive)
                Qt.callLater(root.refresh);
        }
    }

    MediaArtworkResolver {
        id: artworkResolver
        sourceUrl: root.sourceUrl
        title: root.title
        artist: root.artist
        album: root.album
        cacheDirectory: root.cacheDirectory
    }
}