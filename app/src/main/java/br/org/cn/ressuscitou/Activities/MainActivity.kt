package br.org.cn.ressuscitou.Activities

import android.content.Intent
import android.graphics.Color
import android.graphics.PorterDuff
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

        setMenuItemColors()


        addFragment(CanticleFragment.newInstance("ALL",null), false, "songs");
        supportActionBar!!.setTitle("RESSUCITOU");
    }

    fun setMenuItemColors(){
        nav_view.menu.findItem(R.id.nav_song_pre).icon.setColorFilter(Color.parseColor("#efefef"), PorterDuff.Mode.SRC_ATOP)
        nav_view.menu.findItem(R.id.nav_song_liturgic).icon.setColorFilter(Color.parseColor("#fbca8a"), PorterDuff.Mode.SRC_ATOP)
        nav_view.menu.findItem(R.id.nav_song_cat).icon.setColorFilter(Color.parseColor("#a1df86"), PorterDuff.Mode.SRC_ATOP)
        nav_view.menu.findItem(R.id.nav_song_eleition).icon.setColorFilter(Color.parseColor("#73d5f1"), PorterDuff.Mode.SRC_ATOP)

    }


    override fun onBackPressed() {
        if (drawer_layout.isDrawerOpen(GravityCompat.START)) {
            drawer_layout.closeDrawer(GravityCompat.START)
        } else {
            super.onBackPressed()
        }
    }

    override fun onNavigationItemSelected(item: MenuItem): Boolean {
        var category:String? = null;
        var liturgic:String? = null;

        when (item.itemId) {
            R.id.nav_settings->{
                startActivity(Intent(this, Settings::class.java))
            }
            R.id.all ->{
                category = "ALL"
            }
            R.id.nav_song_pre -> {
                category = "PRE_CATECUMENATO"
            }
            R.id.nav_song_liturgic ->{
                category = "LITURGIA"
            }
            R.id.nav_song_cat -> {
                category = "CATECUMENATO"
            }
            R.id.nav_song_eleition -> {
                category = "ELEICAO"
            }
            R.id.nav_advent -> {
                liturgic = "adve"
            }
            R.id.nav_christmans -> {
                liturgic = "nata"
            }
            R.id.nav_lent -> {
                liturgic = "quar"
            }
            R.id.nav_easter -> {
                liturgic = "pasc"
            }
            R.id.nav_pentecost -> {
                liturgic = "pent"
            }
            R.id.nav_input -> {
                liturgic = "entr"
            }
            R.id.nav_peace -> {
                liturgic = "cpaz"
            }
            R.id.nav_fraction -> {
                liturgic = "fpao"
            }
            R.id.nav_communion -> {
                liturgic = "comu"
            }
            R.id.nav_final -> {
                liturgic = "cfin"
            }
            else -> "ALL"
        }

        drawer_layout.closeDrawer(GravityCompat.START)

        if(drawer_layout.isDrawerOpen(GravityCompat.END) == false)
        {
                Handler().postDelayed({
                    Log.i("HANDLER","ONVIEWHANDLER")
                    addFragment(CanticleFragment.newInstance(category, liturgic), false, "songs");
                }, 150)

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
