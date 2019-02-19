package br.org.cn.ressuscitou

import android.graphics.Typeface
import android.os.Bundle
import android.support.design.widget.NavigationView
import android.support.v4.app.Fragment
import android.support.v4.view.GravityCompat
import android.support.v7.app.ActionBarDrawerToggle
import android.support.v7.app.AppCompatActivity
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
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Service.SongService
import br.org.cn.ressuscitou.Utils.ManagePermissions
import com.google.gson.JsonParser
import org.jetbrains.anko.doAsync

import retrofit2.Retrofit
import retrofit2.converter.scalars.ScalarsConverterFactory
import java.util.*


class MainActivity : AppCompatActivity(), NavigationView.OnNavigationItemSelectedListener {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)

        val toggle = ActionBarDrawerToggle(
            this, drawer_layout, toolbar, R.string.navigation_drawer_open, R.string.navigation_drawer_close
        )
        drawer_layout.addDrawerListener(toggle)
        toggle.syncState()

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
//            R.id.nav_song_liturgic -> {
//                fragment = SongsFragment.newInstance("LITURGIA", "Liturgia");
//                title = "Liturgia";
//            }
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
