package br.org.cn.ressuscitou.Fragment

import android.media.MediaPlayer
import android.os.Bundle
import android.os.Handler
import android.provider.MediaStore
import android.support.v4.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.util.Base64
import android.webkit.WebView
import android.widget.CompoundButton
import android.widget.RelativeLayout
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Persistence.Entities.Songs

import br.org.cn.ressuscitou.R
import br.org.cn.ressuscitou.Utils.Preferences
import kotlinx.android.synthetic.main.fragment_song_detail.view.*
import kotlinx.android.synthetic.main.menu_song_detail.view.*
import org.jetbrains.anko.doAsync
import java.io.File
import android.media.AudioManager
import android.util.Log
import java.net.URLEncoder


// TODO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val SONG_ID = "SONGID"

/**
 * A simple [Fragment] subclass.
 * Activities that contain this fragment must implement the
 * [SongDetail.OnFragmentInteractionListener] interface
 * to handle interaction events.
 * Use the [SongDetail.newInstance] factory method to
 * create an instance of this fragment.
 *
 */
class SongDetail : Fragment(), View.OnClickListener {



    // TODO: Rename and change types of parameters
    private var songId: Int? = null
    private var songView: Songs? = null;
    var webView: WebView? = null;
    var player_audio: RelativeLayout? = null;
    val mediaPlayer: MediaPlayer? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            songId = it.getInt(SONG_ID)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {

        val view = inflater.inflate(R.layout.fragment_song_detail, container, false)

        webView = view.findViewById<WebView>(R.id.song_view)
        player_audio = view.findViewById<RelativeLayout>(R.id.player_audio)

        var dbHelper = DataBaseHelper(context);
        var dao = SongsDAO(dbHelper.connectionSource);
        val queryBuilder = dao.queryBuilder();
        queryBuilder.where().eq("id", songId);

        val song = queryBuilder.query();

        view.play_song.setOnClickListener(this);


        songView = song.get(0);


        changeSongView(false);

        return view;
    }


    override fun onClick(v: View?) {
        if(v!!.id == R.id.play_song){
            player_audio!!.visibility = View.VISIBLE;
            playSong();
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

        ScrollRunnable().run()
    }

    fun playSong(){
//        if(!songView!!.url.isNullOrEmpty()) {
//            https://github.com/otaviogrrd/Ressuscitou_Android/blob/master/audios/A%20CEIFA%20DAS%20NACOES.mp3?raw=true
            var titleSong = songView!!.title;

            val titleFile = unnacent(titleSong)


            var url = String.format("https://github.com/otaviogrrd/Ressuscitou_Android/blob/master/audios/%s.mp3?raw=true",titleFile);


            Log.d("URL", url);
            mediaPlayer!!.setAudioStreamType(AudioManager.STREAM_MUSIC);
            mediaPlayer.setDataSource(url);
            mediaPlayer.setVolume(30F, 30F)
            mediaPlayer.prepare();
            mediaPlayer.start();

//        }
    }

    fun unnacent(text: String?) : String{
        val accents 	= "È,É,Ê,Ë,Û,Ù,Ï,Î,À,Â,Ô,è,é,ê,ë,û,ù,ï,î,à,â,ô,Ç,ç,Ã,ã,Õ,õ";
        val expected	= "E,E,E,E,U,U,I,I,A,A,O,e,e,e,e,u,u,i,i,a,a,o,C,c,A,a,O,o";

        val accents2	= "çÇáéíóúýÁÉÍÓÚÝàèìòùÀÈÌÒÙãõñäëïöüÿÄËÏÖÜÃÕÑâêîôûÂÊÎÔÛ";
        val expected2	= "cCaeiouyAEIOUYaeiouAEIOUaonaeiouyAEIOUAONaeiouAEIOU";

        text!!.replace(accents, expected);
        text!!.replace(accents, expected2);

        return text;


    }


    val h = Handler()
    inner class ScrollRunnable() : Runnable{
        override fun run() {
            if(webView!!.canScrollVertically(1)){
                webView!!.scrollBy(0, 0)
                h.postDelayed(this, 17L);
            }
        }

    }



    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment SongDetail.
         */
        // TODO: Rename and change types and number of parameters
        @JvmStatic
        fun newInstance(songId: Int) =
            SongDetail().apply {
                arguments = Bundle().apply {
                    putInt(SONG_ID, songId)
                }
            }
    }
}
