package br.org.cn.ressuscitou

import android.os.Bundle
import android.support.design.widget.NavigationView
import android.support.v4.app.Fragment
import android.support.v4.view.GravityCompat
import android.support.v7.app.ActionBarDrawerToggle
import android.support.v7.app.AppCompatActivity
import android.view.MenuItem
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.app_bar_main.*
import android.util.Log
import android.widget.Toolbar
import br.org.cn.ressuscitou.Fragment.SettingsFragment
import br.org.cn.ressuscitou.Fragment.SongsFragment
import kotlinx.android.synthetic.main.toolbar.*


class MainActivity : AppCompatActivity(), NavigationView.OnNavigationItemSelectedListener {


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(toolbar)

        val toggle = ActionBarDrawerToggle(
            this,
            drawer_layout,
            toolbar,
            R.string.navigation_drawer_open,
            R.string.navigation_drawer_close
        )

        toolbar.setFadingEdgeLength(1000)

        drawer_layout.addDrawerListener(toggle)
        toggle.syncState()

        nav_view.setNavigationItemSelectedListener(this)



        addFragment(SongsFragment.newInstance("ALL", "RESSUCITOU"), false, "songs");
        supportActionBar!!.setTitle(title);
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
            R.id.nav_set_accords -> {
                fragment = SongsFragment.newInstance("ACORDES", "Acordes");
                title = "Acordes";
            }
            R.id.nav_set_settings -> {
                fragment = SettingsFragment.newInstance("ACORDES", "Acordes");
                title = "Configurações";
            }
            R.id.nav_set_harp -> {
                title = "Harpejos";
            }else ->{
                title = "todos"
                fragment = SongsFragment.newInstance("ALL", "RESSUCITOU");
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
        ft.replace(R.id.container, fragment, tag)
        ft.commitAllowingStateLoss()

    }
}
