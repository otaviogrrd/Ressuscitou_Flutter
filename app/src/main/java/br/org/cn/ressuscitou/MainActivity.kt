package br.org.cn.ressuscitou

import android.os.Bundle
import android.support.design.widget.NavigationView
import android.support.v4.app.Fragment
import android.support.v4.view.GravityCompat
import android.support.v7.app.ActionBarDrawerToggle
import android.support.v7.app.AlertDialog
import android.support.v7.app.AppCompatActivity
import android.view.Menu
import android.view.MenuItem
import br.org.cn.ressuscitou.Service.RetrofitInitializer
import br.org.cn.ressuscitou.Utils.Preferences
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.app_bar_main.*
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import android.util.Log
import android.view.View
import android.widget.ProgressBar
import android.widget.Toast
import br.org.cn.ressuscitou.Fragment.SettingsFragment
import br.org.cn.ressuscitou.Fragment.SongsFragment
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Songs
import br.org.cn.ressuscitou.Persistence.SongsDAO
import br.org.cn.ressuscitou.Service.SongService
import br.org.cn.ressuscitou.Utils.ManagePermissions
import com.google.gson.JsonParser
import org.jetbrains.anko.doAsync

import retrofit2.Retrofit
import retrofit2.converter.scalars.ScalarsConverterFactory


class MainActivity : AppCompatActivity(), NavigationView.OnNavigationItemSelectedListener {

    var prefs: Preferences? = null;
    var versionApp = 0;
    val permission = false;

    private val PermissionsRequestCode = 123
    private lateinit var managePermissions: ManagePermissions

    var dbHelper = DataBaseHelper(this);
    var dao = SongsDAO(dbHelper.connectionSource);

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)

        val toggle = ActionBarDrawerToggle(
            this, drawer_layout, toolbar, R.string.navigation_drawer_open, R.string.navigation_drawer_close
        )
        drawer_layout.addDrawerListener(toggle)
        toggle.syncState()

        prefs = Preferences(this)
        versionApp = prefs!!.version

        populateFirst();

        nav_view.setNavigationItemSelectedListener(this)
    }

    override fun onBackPressed() {
        if (drawer_layout.isDrawerOpen(GravityCompat.START)) {
            drawer_layout.closeDrawer(GravityCompat.START)
        } else {
            super.onBackPressed()
        }
    }

    override fun onNavigationItemSelected(item: MenuItem): Boolean {

        var title = "";
        var fragment:Fragment?  = null;


        when (item.itemId) {
            R.id.nav_song_alfabetical -> {
                // Handle the camera action
                title = "Alfabética";
                fragment = SongsFragment.newInstance("ALFABETICA", "Alfabética");
            }
            R.id.nav_song_pre -> {
                title = "Pré-Catecumenato";
                fragment = SongsFragment.newInstance("PRE_CATECUMENATO", "Pré-Catecumenato");
            }
            R.id.nav_song_cat -> {
                title = "Cateocumenato";

                fragment = SongsFragment.newInstance("CATECUMENATO", "Cateocumenato");
            }
            R.id.nav_song_eleition -> {
                fragment = SongsFragment.newInstance("ELEICAO", "Eleição");
                title = "Eleição";
            }
            R.id.nav_song_liturgic -> {
                fragment = SongsFragment.newInstance("LITURGIA", "Liturgia");
                title = "Liturgia";
            }
            R.id.nav_set_accords -> {
                fragment = SongsFragment.newInstance("ACORDES", "Acordes");
                title = "Acordes";
            }
            R.id.nav_set_settings -> {
                fragment = SettingsFragment.newInstance("ACORDES", "Acordes");
                title = "Configurações";
            }
            R.id.nav_set_harp -> {
//                categorySong = "ARPEJOS"
                title = "Harpejos";
            }else ->{
//                categorySong = "ALL";
            title = "todos"
        }
        }


        drawer_layout.closeDrawer(GravityCompat.START)

        if(drawer_layout.isDrawerOpen(GravityCompat.END) == false){
            Log.i("DRAWER", drawer_layout.isDrawerOpen(GravityCompat.START).toString());
            if(fragment != null) {
                addFragment(fragment, false, "songs");
                supportActionBar!!.setTitle(title);

            }
        }


        return true
    }

    fun populateFirst(){
        if(dao.countOf() <= 0){
            val progressBar = findViewById<ProgressBar>(R.id.progressBar);

            progressBar.visibility = View.VISIBLE;

            fetchData(progressBar);
        }else{


            addFragment(SongsFragment.newInstance("ALL", "Todos"), false , "songs");
            supportActionBar!!.setTitle("Todos");
        }
    }

    fun fetchData(progressBar: ProgressBar) {

       val call =  RetrofitInitializer().ressucitouApp().verifyVersion();

        call.enqueue(object: Callback<Int>{
            override fun onFailure(call: Call<Int>, t: Throwable) {

            }

            override fun onResponse(call: Call<Int>, response: Response<Int>) {


                if(response.body()!! > versionApp){
                    fetchSongs(response.body()!!.toInt(), progressBar);
                }
            }

        })


    }

    fun fetchSongs(version: Int, progressBar: ProgressBar){

        val retrofit = Retrofit.Builder()
            .baseUrl("https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/Kotlin/")
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
                                addFragment(SongsFragment.newInstance("ALL", "Todos"), false , "songs");
                                supportActionBar!!.setTitle("Todos");

                                progressBar.visibility = View.GONE;

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

    fun addFragment(fragment: Fragment, addToBackStack: Boolean, tag: String) {

        val manager = supportFragmentManager
        val ft = manager.beginTransaction()

        if (addToBackStack) {
            ft.addToBackStack(tag)
        }
        ft.replace(R.id.container, fragment, tag)
        ft.commitAllowingStateLoss()

    }
}
