package br.org.cn.ressuscitou.Activities

import android.content.Context
import android.content.Intent
import android.net.ConnectivityManager
import android.net.NetworkInfo
import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.view.View
import android.view.Window
import android.view.WindowManager
import android.widget.ProgressBar
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Service.RetrofitInitializer
import br.org.cn.ressuscitou.Utils.Preferences
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.scalars.ScalarsConverterFactory
import br.org.cn.ressuscitou.AsyncTask.ServiceTask
import br.org.cn.ressuscitou.R


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

        context = this.applicationContext

        isConnect()

        if(dao.count() == 0){
            fetchSongs(getVersion(), progressBar);
        }else{

            if(isConnect()) {
                val verifyVersion = getVersion();

                //IF CURRENT VERSION APP INSTALLED IS MAJOR VERSION APP ON REPOSITORY
                if (verifyVersion > versionApp) {
                    //FETCH CANTICLES
                    fetchSongs(verifyVersion, progressBar);
                }
                //IF CURRENT VERSION IS LAST VERSION APP ON REPOSITORY
                else {
                    nextActivity()
                }
            }else{
                nextActivity()
            }
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

        var result = ServiceTask(this, progressBar, retrofit).execute();


    }

    fun isConnect() : Boolean{
        val cm = this.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager
        val activeNetwork: NetworkInfo? = cm.activeNetworkInfo
        val isConnected: Boolean = activeNetwork?.isConnectedOrConnecting == true

        return isConnected
    }

    fun nextActivity(){
        if(prefs!!.accepted_terms) {
            startActivity(Intent(this, MainActivity::class.java))
            finish()
        }else{
            startActivity(Intent(this, AcceptTermsActivity::class.java))
            finish()
        }

    }
}
