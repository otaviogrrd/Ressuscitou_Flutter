package br.org.cn.ressuscitou.ServicesApp

import android.app.Service
import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Handler
import android.os.IBinder
import android.util.Log
import br.org.cn.ressuscitou.Fragment.SongDetail
import br.org.cn.ressuscitou.Utils.UtilitiesAudio
import java.util.concurrent.TimeUnit

class MediaPlayerService : Service(), MediaPlayer.OnCompletionListener{

    var mediaPlayer: MediaPlayer? = null;
    var song: String? = null;
    var stop: Boolean? = null;
    var duration: Long? = null;
    private val durationHandler = Handler()

    override fun onBind(intent: Intent): IBinder? {


        return null;

    }

    override fun onCreate() {


    }

    override fun onStartCommand(intent: Intent, flags: Int, startId: Int): Int {

        song =  intent.extras.getString("SONG");

        Log.d("URI_STRING", song.toString());

        mediaPlayer = MediaPlayer().apply {
            setAudioStreamType(AudioManager.STREAM_MUSIC)
            setDataSource(applicationContext, Uri.parse(song))
            prepare()
        }

        duration = mediaPlayer!!.duration.div(1000).toLong();
        mediaPlayer!!.start()
        mediaPlayer?.setOnCompletionListener(this);

        return Service.START_STICKY
    }

    private val updateSeekBarTime = object : Runnable {
        override fun run() {
            var utilitiesAudio = UtilitiesAudio();
            //get current position
            var current = mediaPlayer!!.currentPosition;
            if(stop!!) {
                var currentTime = formatToDigitalClock(current.toLong())

                var progressPercent = utilitiesAudio.getProgressPercentage(
                    mediaPlayer!!.currentPosition.toLong(),
                    mediaPlayer!!.duration.toLong()
                );


            }
        }
    }

    fun formatToDigitalClock(miliSeconds: Long): String {
        val hours = TimeUnit.MILLISECONDS.toHours(miliSeconds).toInt() % 24
        val minutes = TimeUnit.MILLISECONDS.toMinutes(miliSeconds).toInt() % 60
        val seconds = TimeUnit.MILLISECONDS.toSeconds(miliSeconds).toInt() % 60
        return when {
            hours > 0 -> String.format("%d:%02d:%02d", hours, minutes, seconds)
            minutes > 0 -> String.format("%02d:%02d", minutes, seconds)
            seconds > 0 -> String.format("00:%02d", seconds)
            else -> {
                "00:00"
            }
        }
    }


    override fun onDestroy() {
        if (mediaPlayer!!.isPlaying()) {
            mediaPlayer?.stop()
        }
        mediaPlayer?.release()
    }

    override fun onCompletion(mp: MediaPlayer?) {
        stopSelf();
    }


}
