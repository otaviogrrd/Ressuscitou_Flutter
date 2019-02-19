package br.org.cn.ressuscitou

import android.content.Context
import android.content.Intent
import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.util.Log
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.widget.ProgressBar
import android.widget.Toast
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.Service.RetrofitInitializer
import br.org.cn.ressuscitou.Service.SongService
import br.org.cn.ressuscitou.Utils.Preferences
import com.google.gson.JsonParser
import org.jetbrains.anko.doAsync
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.scalars.ScalarsConverterFactory

class SplashActivity : AppCompatActivity() {

    var prefs: Preferences? = null;
    var versionApp = 0;
    var context: Context? = null;

    var dbHelper = DataBaseHelper(this);
    var dao = SongsDAO(dbHelper.connectionSource);

    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        super.onCreate(savedInstanceState)

        window.setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN)
        setContentView(R.layout.activity_splash)

        supportActionBar!!.hide()

        prefs = Preferences(this)
        versionApp = prefs!!.version

        val progressBar = findViewById<ProgressBar>(R.id.progressbarupdate)


        //progressBar.progressDrawable.setColorFilter(Color.WHITE,  android.graphics.PorterDuff.Mode.SRC_IN)

        context = this.applicationContext

        //VERIFY SIZE COUNTOF CANTICLES
        if(dao.countOf() > 0){
            val verifyVersion = getVersion();

            //IF CURRENT VERSION APP INSTALLED IS MAJOR VERSION APP ON REPOSITORY
            if(verifyVersion > versionApp){
                //FETCH CANTICLES
                fetchSongs(verifyVersion, progressBar);
            }
            //IF CURRENT VERSION IS LAST VERSION APP ON REPOSITORY
            else{
                startActivity(Intent(this, MainActivity::class.java))
                finish()
            }
        }
        //IF EMPTY CANTICLES ON APP
        else{
            fetchSongs(getVersion(), progressBar);
        }
    }


    fun getVersion() : Int{

        var appversion = versionApp;


        val call =  RetrofitInitializer().ressucitouApp().verifyVersion();
        call.enqueue(object: Callback<Int> {
            override fun onFailure(call: Call<Int>, t: Throwable) {

            }

            override fun onResponse(call: Call<Int>, response: Response<Int>) {
                appversion = response.body()!!.toInt();
            }

        })

        return appversion;
    }


    fun fetchSongs(version: Int, progressBar: ProgressBar)
    {
        progressBar.visibility = View.VISIBLE;

        val retrofit = Retrofit.Builder()
                .baseUrl("https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/")
                .addConverterFactory(ScalarsConverterFactory.create())
                .build()

        doAsync {
            val call = retrofit.create(SongService::class.java);

            call.getSongs().enqueue(object: Callback<String>{
                override fun onFailure(call: Call<String>, t: Throwable) {
                    Log.i("ERROR_R", "request not working")
                }

                override fun onResponse(call: Call<String>, response: Response<String>) {
                    if(response.isSuccessful){
                        if(response.body() != null){
                            var parser = JsonParser();
                            var arr = parser.parse(response.body().toString()).asJsonArray;

                            for(item in arr){
                                var obj = item as com.google.gson.JsonObject
                                var songs = Songs()
                                songs.title = obj.get("titulo").asString;
                                songs.numero = obj.get("numero").asString;
                                songs.categoria = obj.get("categoria").asInt
                                songs.adve = obj.get("adve").asBoolean
                                songs.laud = obj.get("adve").asBoolean
                                songs.entr = obj.get("entr").asBoolean
                                songs.nata = obj.get("nata").asBoolean
                                songs.quar = obj.get("quar").asBoolean
                                songs.pasc = obj.get("pasc").asBoolean
                                songs.pent = obj.get("pent").asBoolean
                                songs.virg = obj.get("virg").asBoolean
                                songs.cria = obj.get("cria").asBoolean
                                songs.cpaz = obj.get("cpaz").asBoolean
                                songs.fpao = obj.get("fpao").asBoolean
                                songs.comu = obj.get("comu").asBoolean
                                songs.cfin = obj.get("cfin").asBoolean
                                songs.conteudo = obj.get("conteudo").asString
                                songs.html_base64 = obj.get("html_base64").asString
                                songs.ext_base64 = obj.get("ext_base64").asString
                                dao.create(songs);
                            }

                            if(dao.countOf() > 0) {

                                progressBar.visibility = View.GONE;
                                startActivity(Intent(context, MainActivity::class.java))
                                finish()

                            }else{
                                Toast.makeText(applicationContext, "não foi possivel atualizar", Toast.LENGTH_SHORT).show();
                            }
                        }else{
                            Log.i("onEmptyResponse", "Returned empty response");
                        }
                    }
                }
            })
        }
    }
}
