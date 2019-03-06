package br.org.cn.ressuscitou.Fragment

import android.content.Intent
import android.media.AudioManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.support.v4.app.Fragment
import android.util.Base64
import android.webkit.WebView
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Persistence.Entities.Songs

import br.org.cn.ressuscitou.R
import java.io.File
import android.view.*
import br.org.cn.ressuscitou.MainActivity
import android.os.StrictMode
import android.text.format.DateUtils
import android.widget.*
import br.org.cn.ressuscitou.Utils.Common
import android.support.v7.widget.Toolbar
import android.util.Log
import java.util.concurrent.TimeUnit
import android.view.MenuInflater
import android.view.animation.AnimationUtils
import br.org.cn.ressuscitou.Utils.UtilitiesAudio
import kotlinx.android.synthetic.main.toolbar.*
import kotlinx.android.synthetic.main.toolbar.view.*
import android.widget.ToggleButton
import br.org.cn.ressuscitou.AsyncTask.AudioDownload
import br.org.cn.ressuscitou.ServicesApp.MediaPlayerService


private const val SONG_ID = "SONGID"

class SongDetail : Fragment() {



    // TODO: Rename and change types of parameters
    private var songId: Int? = null
    private var songView: Songs? = null;

    var audioFile: String? = null;
    var webView: WebView? = null;
    var player_audio: LinearLayout? = null;
    var progress_download: LinearLayout? = null;
    var time_all: TextView? = null;
    var controlplayer: ImageButton? = null
    var wrapper_player: RelativeLayout? = null;
    var progresstime: SeekBar? = null;
    var media: Intent? = null;
    var feedback_msg: TextView? = null;




    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            songId = it.getInt(SONG_ID)
        }

        if(android.os.Build.VERSION.SDK_INT > 9){
            val policy = StrictMode.ThreadPolicy.Builder().permitAll().build();
            StrictMode.setThreadPolicy(policy);

        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {

        val view = inflater.inflate(R.layout.fragment_song_detail, container, false)

        setHasOptionsMenu(true);

        val toolbar = (activity as MainActivity).toolbar


        var dbHelper = DataBaseHelper(context);
        var dao = SongsDAO(dbHelper.connectionSource);

        media = Intent(context, MediaPlayerService::class.java);

        //CASTS
        webView = view.findViewById<WebView>(R.id.song_view)
        player_audio = view.findViewById<LinearLayout>(R.id.player_audio);
        controlplayer = view.findViewById<ImageButton>(R.id.controlplayer);
        time_all = view.findViewById<TextView>(R.id.time_all);
        wrapper_player  =view.findViewById<RelativeLayout>(R.id.wrapper_player);
        progress_download = view.findViewById<LinearLayout>(R.id.progress_download);
        progresstime = view.findViewById<SeekBar>(R.id.progresstime)
        feedback_msg = view.findViewById<TextView>(R.id.feedback_msg);

        val queryBuilder = dao.queryBuilder();
        queryBuilder.where().eq("id", songId);

        val song = queryBuilder.query();

        songView = song.get(0);

        (activity as MainActivity).supportActionBar?.title = songView!!.title

        audioFile = Common().unaccent(songView!!.title!!) + ".mp3";


        initToolBar(toolbar);
        changeSongView(false);

        return view;
    }

    fun initToolBar(toolbar: Toolbar) {
        toolbar.section_title.setText(songView!!.title!!.toUpperCase())
        toolbar.section_title.compoundDrawablePadding = 0;
        toolbar.bt_search.visibility = View.GONE;
        toolbar.options.visibility = View.VISIBLE;
        toolbar.bt_audio.visibility = View.VISIBLE;

        var showPlayer: Boolean = false;

        var animation = AnimationUtils.loadAnimation(context, R.anim.bounce);

        if(songView!!.url.equals("X",true)){
            toolbar.bt_audio.visibility = View.VISIBLE;

            toolbar.bt_audio.setOnClickListener({
                if(showPlayer == false)
                {
                    showPlayer = true;
                }else{
                    showPlayer = false;
                }

                wrapper_player?.animation = animation;

                if(songView!!.hasaudio) {

                    if (showPlayer) {

                        wrapper_player?.visibility = View.VISIBLE;
                        player_audio?.visibility = View.VISIBLE;

                        controlMediaPlayer();
                    } else {
                        wrapper_player?.visibility = View.GONE;
                        player_audio?.visibility = View.GONE;
                    }
                }else{
                    wrapper_player?.visibility = View.VISIBLE;
                    progress_download?.visibility = View.VISIBLE;

                    AudioDownload(context, songView!!.title, songView!!.id, this, progress_download, player_audio, feedback_msg).execute();
                }


            });
        }else{
            toolbar.bt_audio.visibility = View.GONE;
        }

    }


    override fun onDestroy() {
        super.onDestroy()
        context!!.stopService(media);
    }

    fun controlMediaPlayer(){
        if(existFile())
        {
            media?.putExtra("SONG", getUriSongDownloaded());

            var isPlaing = false;
            controlplayer?.setOnClickListener({
                Log.d("SONG_URI", getUriSongDownloaded().toString());
                if(isPlaing == false)
                {
                    isPlaing = true;
                }else{
                    isPlaing = false;
                }

                if(isPlaing)
                {
                    context!!.startService(media);
                    controlplayer?.setBackgroundResource(R.drawable.ic_pause);

                }else{
                    context!!.stopService(media);
                    controlplayer?.setBackgroundResource(R.drawable.ic_play);
                }
            })
        }
    }



    fun changeSongView(
        extend: Boolean
    )
    {
        var base64Str: String? = null;

        if(extend == true){
            base64Str = songView!!.ext_base64
        }else{
            base64Str = songView!!.html_base64;
        }


        val path = context!!.filesDir
        val file = File(path, "temp.html")

        file.writeBytes(Base64.decode(base64Str!!.toByteArray(), Base64.DEFAULT))
        webView!!.loadUrl("file://" + path + "/temp.html" )

    }


    fun getUriSongDownloaded() : String{

        var filePath = "";

        val file = File(context!!.getExternalFilesDir(null).toString() + File.separator + audioFile);


        if(existFile()){
            filePath = file.toURI().toString();
        }

        return filePath;

    }

    fun existFile(): Boolean
    {
        val file = File(context!!.getExternalFilesDir(null).toString() + File.separator + audioFile);

        return file.exists()
    }

    companion object {

        @JvmStatic
        fun newInstance(songId: Int) =
            SongDetail().apply {
                arguments = Bundle().apply {
                    putInt(SONG_ID, songId)
                }
            }
    }
}
