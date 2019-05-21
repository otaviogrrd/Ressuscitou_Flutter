package br.org.cn.ressuscitou.Fragment

import android.content.Intent
import android.os.Bundle
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
import android.support.v7.widget.SearchView
import android.widget.*
import br.org.cn.ressuscitou.Utils.Common
import android.support.v7.widget.Toolbar
import android.util.Log
import android.view.animation.AnimationUtils
import kotlinx.android.synthetic.main.toolbar.view.*
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
    var wrapper_player: RelativeLayout? = null;
    var media: Intent? = null;
    var feedback_msg: TextView? = null;
    var frame: FrameLayout? = null;




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

        var dbHelper = DataBaseHelper(context);
        var dao = SongsDAO(dbHelper.connectionSource);

        media = Intent(context, MediaPlayerService::class.java);

        //CASTS
        webView = view.findViewById<WebView>(R.id.song_view)

        feedback_msg = view.findViewById<TextView>(R.id.feedback_msg);
        frame = view.findViewById<FrameLayout>(R.id.child_fragment_container)

        val queryBuilder = dao.queryBuilder();
        queryBuilder.where().eq("id", songId);

        val song = queryBuilder.query();

        songView = song.get(0);

        (activity as MainActivity).supportActionBar?.title = songView!!.title

        audioFile = Common().unaccent(songView!!.title!!) + ".mp3";

        changeSongView(false);

        return view;
    }


    override fun onCreateOptionsMenu(menu: Menu?, inflater: MenuInflater?) {
        inflater!!.inflate(R.menu.menu_song_detail,menu)

        val item = menu!!.findItem(R.id.btn_audio);
        item.setOnMenuItemClickListener(object: MenuItem.OnMenuItemClickListener {
            override fun onMenuItemClick(item: MenuItem?): Boolean {
                if(existFile())
                {
                    insertNestedFragment(getUriSongDownloaded(),songView!!.title.toString(), songView!!.id,"player");
                }else{
                    insertNestedFragment(getUriSongDownloaded(),songView!!.title.toString(), songView!!.id,"loading");
                }
                frame!!.visibility = View.VISIBLE;

                return true
            }

        })
    }


    override fun onDestroy() {
        super.onDestroy()
        context!!.stopService(media);
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

    private fun insertNestedFragment(uriSongDownloaded: String, title: String, id:Int,  view: String) {

        val childFragment = AudioPlayer()

        var bundle = Bundle();
        bundle.putString("VIEW", view);
        bundle.putString("SONG_URI", uriSongDownloaded)
        bundle.putString("TITLE",title)
        bundle.putInt("ID", id)
        childFragment.arguments = bundle
        val transaction = childFragmentManager.beginTransaction()
        transaction.replace(R.id.child_fragment_container, childFragment).commit()
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
