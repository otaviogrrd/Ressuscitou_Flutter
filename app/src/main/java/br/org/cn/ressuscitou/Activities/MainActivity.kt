package br.org.cn.ressuscitou.Activities

import android.os.Bundle
import android.os.Handler
import android.support.design.widget.NavigationView
import android.support.v4.app.Fragment
import android.support.v4.view.GravityCompat
import android.support.v7.app.ActionBarDrawerToggle
import android.support.v7.app.AppCompatActivity
import android.view.MenuItem
import kotlinx.android.synthetic.main.activity_main.*
import kotlinx.android.synthetic.main.app_bar_main.*
import android.util.Log
import br.org.cn.ressuscitou.Fragment.CanticleFragment
import br.org.cn.ressuscitou.R
import kotlinx.android.synthetic.main.activity_main.view.*


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
        
        drawer_layout.addDrawerListener(toggle)
        toggle.syncState()

        nav_view.setNavigationItemSelectedListener(this)



        addFragment(CanticleFragment.newInstance("ALL"), false, "songs");
        supportActionBar!!.setTitle("RESSUCITOU");
    }

    override fun onBackPressed() {
        if (drawer_layout.isDrawerOpen(GravityCompat.START)) {
            drawer_layout.closeDrawer(GravityCompat.START)
        } else {
            super.onBackPressed()
        }
    }

    override fun onNavigationItemSelected(item: MenuItem): Boolean {
        var fragment:Fragment?  = null;

        var categorySong = when (item.itemId) {
            R.id.nav_song_alfabetical -> "ALFABETICA"
            R.id.nav_song_pre -> "PRE_CATECUMENATO"
            R.id.nav_song_cat -> "CATECUMENATO"
            R.id.nav_song_eleition -> "ELEICAO"
            R.id.nav_set_accords -> "ACORDES"
            R.id.nav_set_harp -> "Harpejos"
            else -> "ALL"
        }

        drawer_layout.closeDrawer(GravityCompat.START)

        if(drawer_layout.isDrawerOpen(GravityCompat.END) == false)
        {
                Handler().postDelayed({
                    Log.i("HANDLER","ONVIEWHANDLER")
                    addFragment(CanticleFragment.newInstance(categorySong), false, "songs");
                }, 100)

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
