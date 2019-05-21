package br.org.cn.ressuscitou

import android.content.Intent
import android.support.v7.app.AppCompatActivity
import android.os.Bundle
import android.view.Window
import android.view.WindowManager
import br.org.cn.ressuscitou.Utils.Preferences
import kotlinx.android.synthetic.main.activity_accept_terms.*

class AcceptTermsActivity : AppCompatActivity() {

    var prefs: Preferences? = null;
    var acceptedTerms: Boolean? = false;


    override fun onCreate(savedInstanceState: Bundle?) {
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        super.onCreate(savedInstanceState)

        window.setFlags(
            WindowManager.LayoutParams.FLAG_FULLSCREEN,
            WindowManager.LayoutParams.FLAG_FULLSCREEN)
        setContentView(R.layout.activity_accept_terms)
        supportActionBar!!.hide()

        prefs = Preferences(this)
        acceptedTerms = prefs!!.accepted_terms

        if(prefs!!.accepted_terms){
            startActivity(Intent(this, MainActivity::class.java))
        }
        accepted.setOnClickListener({
            prefs!!.accepted_terms = true;
            startActivity(Intent(this, MainActivity::class.java))
            finish()
        })
    }
}
