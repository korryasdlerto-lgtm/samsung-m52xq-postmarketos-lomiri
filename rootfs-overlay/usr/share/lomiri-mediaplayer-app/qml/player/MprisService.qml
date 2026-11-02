import QtQuick 2.4
import QtMultimedia 5.6
import org.nemomobile.mpris 1.0

Item
{
    property var player: null

    MprisPlayer
    {
        serviceName: "lomiri-mediaplayer-app"
        supportedUriSchemes: ["file"]
        canQuit: false
        canRaise: false
        canSetFullscreen: false
        hasTrackList: false
        desktopEntry: "lomiri-mediaplayer-app"
        identity: "Lomiri Media Player App"
        canControl: player && player.video && player.video.source != ""
        canPlay: true
        canGoNext: false
        canGoPrevious: false
        canPause: true
        canSeek: false
        playbackStatus:
        {
            if (!player || !player.video)
                return Mpris.Stopped;
            else if (player.video.playbackState == MediaPlayer.PlayingState)
                return Mpris.Playing;
            else if (player.video.playbackState == MediaPlayer.PausedState)
                return Mpris.Paused
            else
                return Mpris.Stopped;
        }

        metadata:
        {
            let pMetadata = {};

            if (player && player.video && player.video.metaData)
            {
                if (player.video.metaData.author != null)
                {
                    pMetadata["xesam:artist"] = [player.video.metaData.author];
                }

                if (player.video.metaData.title != null)
                {
                    pMetadata["xesam:title"] = player.video.metaData.title;
                }

                if (player.video.metaData.albumTitle != null)
                {
                    pMetadata["xesam:album"] = player.video.metaData.albumTitle;
                }

                if (player.video.metaData.coverArtUrlSmall != null)
                {
                    pMetadata["mpris:artUrl"] = player.video.metaData.coverArtUrlSmall;
                }
                else if (player.video.metaData.coverArtUrlLarge != null)
                {
                    pMetadata["mpris:artUrl"] = player.video.metaData.coverArtUrlLarge;
                }
                else if (player.video.metaData.posterUrl != null)
                {
                    pMetadata["mpris:artUrl"] = player.video.metaData.posterUrl;
                }
                else
                {
                    pMetadata["mpris:artUrl"] = APP_ICON;
                }
            }

            return pMetadata;
        }

        onPlayRequested:
        {
            player.video.play ();
        }

        onPauseRequested:
        {
            player.video.pause ();
        }

        onStopRequested:
        {
            player.video.stop ();
        }

        onPlayPauseRequested:
        {
            player.togglePause ();
        }
    }
}
