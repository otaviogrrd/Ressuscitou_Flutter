package br.org.cn.ressuscitou.Adapter

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.support.v7.widget.RecyclerView
import android.support.v7.widget.RecyclerView.Adapter
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import br.org.cn.ressuscitou.Fragment.SongsFragment
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.R
import kotlinx.android.synthetic.main.song_item.view.*
import android.support.v4.app.FragmentManager
import br.org.cn.ressuscitou.Fragment.SongDetail


class SongAdapter(
    private val songs: List<Songs>,
    private val context: Context?,
    manager: FragmentManager
) : Adapter<ViewHolder>(){

    val fragment = SongsFragment
    val manager = manager;


    override fun onCreateViewHolder(parent: ViewGroup, viewType: Int): ViewHolder {
        val view = LayoutInflater.from(context).inflate(R.layout.song_item, parent, false)


        return ViewHolder(view);
    }

    override fun getItemCount(): Int {
        return songs.size
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        val song =songs[position]

        val colorStr: String = colorsByCategory(song.categoria);

        var drawable = GradientDrawable();
        drawable.setColor(Color.parseColor("#"+colorStr));
        drawable.cornerRadius = 90.0f
        drawable.setStroke(1, Color.rgb(255,255,255));


        holder?.wrapper.setOnClickListener({
            manager.beginTransaction().replace(R.id.container, SongDetail.newInstance(song.id)).addToBackStack(null).commit()
        })



        holder?.page.background = drawable
        holder?.page.text = song.numero
        holder?.title.text = song.title

    }





    fun colorsByCategory(category:Int): String {
        val colors = arrayOf<String>("d5d5d5","6da3d1","6dd175","f2e2a0");
        val response: String;

        if(!colors[category -1].isNullOrEmpty()){
            response = colors[category -1].toString();
        }else{
            response = colors[0].toString();
        }
        return response;

    }
}

class ViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
    var page = itemView.song_page_number
    var title = itemView.song_title
    var wrapper = itemView.song_item
}