package br.org.cn.ressuscitou

import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.util.Base64
import android.util.Log
import android.webkit.WebView
import android.widget.Toast
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Songs
import br.org.cn.ressuscitou.Persistence.SongsDAO
import br.org.cn.ressuscitou.Utils.Preferences
import java.io.File

class SongActivity : AppCompatActivity() {

    var prefs: Preferences? = null;
    var EXT_MOD: Boolean? = false;

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_song)

        val actionbar = supportActionBar

        val webView = findViewById<WebView>(R.id.song_view)

        var itemId  = intent.getIntExtra("SONG_ID", 0);

        var dbHelper = DataBaseHelper(this);
        var dao = SongsDAO(dbHelper.connectionSource);
        val queryBuilder = dao.queryBuilder();
        queryBuilder.where().eq("id", itemId);

        val song = queryBuilder.query();


        val path = this.filesDir
        val file = File(path, "temp.html")

        prefs = Preferences(this)
        EXT_MOD = prefs!!.settings_mod

        if(song.get(0) != null)
        {

            actionbar!!.title = "Cântico - "+song.get(0).title;

            actionbar.setDisplayHomeAsUpEnabled(true);
            actionbar.setDisplayShowHomeEnabled(true);

            var base64Str: String? = null;

            if(EXT_MOD == true){
                base64Str = song.get(0).ext_base64;
            }else{
                base64Str = song.get(0).html_base64;
            }

            file.writeBytes(Base64.decode(base64Str!!.toByteArray(),Base64.DEFAULT))
            webView!!.loadUrl("file://" + path + "/temp.html" )
        }



    }

}
