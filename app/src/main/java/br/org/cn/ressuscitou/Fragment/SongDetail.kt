package br.org.cn.ressuscitou.Fragment

import android.os.Bundle
import android.support.v4.app.Fragment
import android.util.Base64
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.webkit.WebView
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO

import br.org.cn.ressuscitou.R
import br.org.cn.ressuscitou.Utils.Preferences
import java.io.File

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
class SongDetail : Fragment() {
    // TODO: Rename and change types of parameters
    private var songId: Int? = null

    var prefs: Preferences? = null;
    var EXT_MOD: Boolean? = false;

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
        // Inflate the layout for this fragment

        val webView = view.findViewById<WebView>(R.id.song_view)

        var dbHelper = DataBaseHelper(context);
        var dao = SongsDAO(dbHelper.connectionSource);
        val queryBuilder = dao.queryBuilder();
        queryBuilder.where().eq("id", SONG_ID);

        val song = queryBuilder.query();


        val path = context!!.filesDir
        val file = File(path, "temp.html")


        //SongsFragment().activity!!.supportFragmentManager

        prefs = Preferences(SongDetail().activity!!)
        EXT_MOD = prefs!!.settings_mod

        if(song.get(0) != null)
        {

            var base64Str: String? = null;

            if(EXT_MOD == true){
                base64Str = song.get(0).ext_base64;
            }else{
                base64Str = song.get(0).html_base64;
            }

            file.writeBytes(Base64.decode(base64Str!!.toByteArray(), Base64.DEFAULT))
            webView!!.loadUrl("file://" + path + "/temp.html" )
        }


        return view;
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
