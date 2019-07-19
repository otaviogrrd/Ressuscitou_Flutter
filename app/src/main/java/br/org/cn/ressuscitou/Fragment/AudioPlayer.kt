package br.org.cn.ressuscitou.Fragment

import android.animation.ObjectAnimator
import android.graphics.Color
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.StrictMode
import android.support.v4.app.Fragment
import android.support.v4.content.ContextCompat
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.animation.LinearInterpolator
import android.widget.*
import br.org.cn.ressuscitou.AsyncTask.AudioDownload

import br.org.cn.ressuscitou.R
import br.org.cn.ressuscitou.Utils.Common
import br.org.cn.ressuscitou.Utils.UtilitiesAudio
import rm.com.audiowave.AudioWaveView
import java.io.File
import java.util.concurrent.TimeUnit
import java.io.FileInputStream
import java.io.IOException


private const val SONG_URI = "SONG_URI"
private const val VIEW_SHOW = "VIEW"
private const val SONG_TITLE = "TITLE"
private const val SONG_ID = "ID"


class AudioPlayer : Fragment(), View.OnClickListener {



    private var songUri: String? = null
    private var viewShow:String? = null;
    private var songTitle:String?= null;
    private var songId:Int? = 0;

    var player_audio: LinearLayout? = null;
    var progress_download: LinearLayout? = null;
    var time_all: TextView? = null;
    var btn_play: ImageButton? = null
    var btn_pause: ImageButton? = null
    var wrapper_player: RelativeLayout? = null;
    var feedback_msg:TextView? = null;
    var waveformSeekBar:AudioWaveView? = null







    var mediaPlayer: MediaPlayer? = null;

    var timeToMove:Int? = 0

    var currentTime: Int? = null;

    private val durationHandler = Handler()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)


        arguments?.let {
            songUri = it.getString(SONG_URI)
            viewShow = it.getString(VIEW_SHOW)
            songTitle = it.getString(SONG_TITLE)
            songId = it.getInt(SONG_ID)
        }

        strictMode()


    }

    fun strictMode(){
        if(android.os.Build.VERSION.SDK_INT > 9){
            val policy = StrictMode.ThreadPolicy.Builder().permitAll().build();
            StrictMode.setThreadPolicy(policy);
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {

        var view = inflater.inflate(R.layout.fragment_audio_player, container, false);

        player_audio = view.findViewById<LinearLayout>(R.id.player_audio);
        btn_play = view.findViewById<ImageButton>(R.id.btn_play);
        btn_pause = view.findViewById<ImageButton>(R.id.btn_pause);
        time_all = view.findViewById<TextView>(R.id.time_all);
        wrapper_player  =view.findViewById<RelativeLayout>(R.id.wrapper_player);
        progress_download = view.findViewById<LinearLayout>(R.id.progress_download);
        feedback_msg = view.findViewById<TextView>(R.id.feedback_msg)

        waveformSeekBar = view.findViewById<AudioWaveView>(R.id.progresstime)


        Log.d("show", viewShow);
        if(viewShow == "loading")
        {
            AudioDownload(context, songTitle, songId, feedback_msg,this).execute();
            wrapper_player?.visibility = View.VISIBLE
            progress_download?.visibility = View.VISIBLE
        }

        if(viewShow == "player"){

            wrapper_player?.visibility = View.GONE
            progress_download?.visibility = View.GONE

            progress_download?.visibility = View.GONE
            wrapper_player?.visibility = View.VISIBLE
            player_audio?.visibility = View.VISIBLE;

            controlElementPlayer("stop")
        }


        btn_play?.setOnClickListener(this);
        btn_pause?.setOnClickListener(this);


        return view;
    }


    override fun onClick(v: View?)
    {

        if(v!!.id == R.id.btn_play){
            controlElementPlayer("play")
            loadMediaPlayer(getUriSongDownloaded(), "play")
        }

        if(v!!.id == R.id.btn_pause)
        {
            if(mediaPlayer!!.isPlaying()){
                controlElementPlayer("stop")

                mediaPlayer!!.pause()
            }
        }
    }

    fun loadMediaPlayer(songUri: String, action:String){
        mediaPlayer = MediaPlayer().apply {
            setAudioStreamType(AudioManager.STREAM_MUSIC)
            setDataSource(context, Uri.parse(songUri))
            prepare()
        }

        if(action == "play" && !mediaPlayer!!.isPlaying()) {
            controlElementPlayer("play")
            mediaPlayer!!.seekTo(timeToMove!!)
            mediaPlayer!!.start();

            inflateWave()



            durationHandler.postDelayed(updateSeekBarTime, 1000);
        }


    }

    private val updateSeekBarTime = object : Runnable {
        override fun run() {
            var utilitiesAudio = UtilitiesAudio();
            //get current position
            var current = mediaPlayer!!.currentPosition;
            if(mediaPlayer!!.isPlaying()) {
                var now = formatToDigitalClock(current.toLong())

                currentTime = current.toInt();

                var progressPercent = utilitiesAudio.getProgressPercentage(
                    mediaPlayer!!.currentPosition.toLong(),
                    mediaPlayer!!.duration.toLong()
                );

                waveformSeekBar!!.progress = progressPercent.toFloat()


                if(progressPercent >= 99){
                    Handler().postDelayed({
                        progressPercent = 0;
                        controlElementPlayer("stop")
                        now = "0.00"
                        timeToMove = 0

                        waveformSeekBar!!.progress = 0.0f

                    }, 2500)

                }

                time_all!!.setText(now);
                Log.d("PROGRESS_TIME", progressPercent.toString())
            }



            Handler().postDelayed(this, 1000)
        }
    }


    override fun onDestroy() {
        super.onDestroy()

        if(mediaPlayer!!.isPlaying()){
            mediaPlayer!!.stop();
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

    fun controlElementPlayer(stage:String){
        if(stage == "play")
        {

            btn_play!!.visibility = View.GONE;
            btn_pause!!.visibility = View.VISIBLE;

        }else if(stage == "stop")
        {

            btn_pause!!.visibility = View.GONE;
            btn_play!!.visibility = View.VISIBLE;

        }else if(stage == "finishDownload"){
            wrapper_player?.visibility = View.GONE
            progress_download?.visibility = View.GONE

            progress_download?.visibility = View.GONE
            wrapper_player?.visibility = View.VISIBLE
            player_audio?.visibility = View.VISIBLE;
        }
    }

    fun completeDownload() {

        viewShow = "finishDownload"

        if(viewShow == "finishDownload")
        {
            controlElementPlayer("finishDownload")
            loadMediaPlayer(getUriSongDownloaded(),"play")
        }
    }

    fun getUriSongDownloaded() : String{

        var audioFile = Common().unaccent(songTitle!!) + ".mp3";

        val file = File(context!!.getExternalFilesDir(null).toString() + File.separator + audioFile);

        return file.toURI().toString();

    }

    private fun inflateWave() {


        var animator = ObjectAnimator.ofFloat(waveformSeekBar, "progress", 0F, 100F).apply {
                interpolator = LinearInterpolator()
                duration = 1000
            }

        waveformSeekBar!!.setRawData(fileToBytes(File(getUriSongDownloaded()))) { animator.start() }

        waveformSeekBar!!.onProgressChanged = { progress, byUser ->

            if (progress == 100F && !byUser) {
                waveformSeekBar!!.waveColor = ContextCompat.getColor(context!!, R.color.colorWhite)
                waveformSeekBar!!.isTouchable = true
            }
        }
    }

    fun fileToBytes(file: File): ByteArray {
        var bytes = ByteArray(0)
        try {
            FileInputStream(file).use({ inputStream ->
                bytes = ByteArray(inputStream.available())

                inputStream.read(bytes)
            })
        } catch (e: IOException) {
            e.printStackTrace()
        }

        return bytes
    }

    companion object {
        @JvmStatic
        fun newInstance(songUri: String, viewShow: String, songTitle:String, id:Int) =
            AudioPlayer().apply {
                arguments = Bundle().apply {
                    putString(SONG_URI, songUri.toString());
                    putString(VIEW_SHOW, viewShow.toString());
                    putString(SONG_TITLE, songTitle.toString());
                    putInt(SONG_ID, id);
                }
            }
    }
}
