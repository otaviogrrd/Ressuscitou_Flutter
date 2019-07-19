package br.org.cn.ressuscitou.Activities

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkInfo
import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.os.StrictMode
import android.support.v4.app.Fragment
import android.util.Base64
import android.util.Log
import android.view.*
import android.webkit.WebView
import android.widget.FrameLayout
import android.widget.TextView
import android.widget.Toast
import br.org.cn.ressuscitou.Fragment.AudioPlayer
import br.org.cn.ressuscitou.Fragment.CanticleFragment
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.R
import br.org.cn.ressuscitou.ServicesApp.MediaPlayerService
import br.org.cn.ressuscitou.Utils.Common
import kotlinx.android.synthetic.main.fragment_canticle_detail.*
import java.io.File

private const val SONG_ID = "SONGID"

class CanticleDetail : AppCompatActivity() {

    var songId: Int? = null
    var songView: Songs? = null;

    var audioFile: String? = null;
    var webView: WebView? = null;
    var media: Intent? = null;
    var feedback_msg: TextView? = null;
    var frame: FrameLayout? = null;

    var dbHelper = DataBaseHelper(this);
    var dao = SongsDAO(dbHelper.connectionSource);

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        var extras = intent.extras;
        if(null != extras){
            songId = extras.getInt(SONG_ID);
        }

        setContentView(R.layout.activity_canticle_detail)

        supportActionBar?.setDisplayHomeAsUpEnabled(true)

        webView = song_view;
        feedback_msg = feedback_msg;
        frame = child_fragment_container

        val queryBuilder = dao.queryBuilder();
        queryBuilder.where().eq("id", songId);
        val song = queryBuilder.query();

        songView = song.get(0);

        this.supportActionBar?.title = songView!!.title
        audioFile = Common().unaccent(songView!!.title!!) + ".mp3";
        changeSongView(false);
        media = Intent(this, MediaPlayerService::class.java);
    }


    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        val inflater = menuInflater
        inflater.inflate(R.menu.menu_song_detail, menu)

        var item = menu.findItem(R.id.btn_audio);


        if(!songView!!.url.equals("X",true)){
            item.setVisible(false)
        }


        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean = when (item.itemId) {

        android.R.id.home -> {
            onBackPressed()
            true
        }

        R.id.btn_audio -> {
            canticleAudio()
            true
        }

        else -> super.onOptionsItemSelected(item)
    }

    fun canticleAudio(){
        if(!isConnect()){
            Toast.makeText(applicationContext, "Sem internet", Toast.LENGTH_SHORT).show()
        }else{
            var action = when(existFile()){
                true -> "player"
                false -> "loading"
            }

            createAudioPlayer(
                getUriSongDownloaded(),
                songView!!.title.toString(),
                songView!!.id,
                action
            );
            frame!!.visibility = View.VISIBLE;
        }
    }


    override fun onDestroy() {
        super.onDestroy()
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


        val path = this!!.filesDir
        val file = File(path, "temp.html")

        file.writeBytes(Base64.decode(base64Str!!.toByteArray(), Base64.DEFAULT))
        webView!!.loadUrl("file://" + path + "/temp.html" )

    }


    fun getUriSongDownloaded() : String{

        var filePath = "";

        val file = File(this!!.getExternalFilesDir(null).toString() + File.separator + audioFile);


        if(existFile()){
            filePath = file.toURI().toString();
        }

        return filePath;

    }

    fun existFile(): Boolean
    {
        val file = File(this!!.getExternalFilesDir(null).toString() + File.separator + audioFile);

        return file.exists()
    }
    private fun createAudioPlayer(uriSongDownloaded: String, title: String, id:Int,  view: String) {
        addFragment(AudioPlayer.newInstance(uriSongDownloaded,view,title,id), false, "audio");
    }

    fun addFragment(
        fragment: Fragment,
        addToBackStack: Boolean,
        tag: String
    ) {

        val manager = supportFragmentManager
        val ft = manager.beginTransaction()

        if (addToBackStack) {
            ft.addToBackStack(tag)
        }
        ft.replace(R.id.child_fragment_container, fragment, tag)
        ft.commitAllowingStateLoss()
    }

    fun isConnect() : Boolean{
        val cm = this!!.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork: NetworkInfo? = cm.activeNetworkInfo
        val isConnected: Boolean = activeNetwork?.isConnectedOrConnecting == true

        return isConnected
    }
}