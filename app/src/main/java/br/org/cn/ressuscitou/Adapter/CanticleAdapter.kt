package br.org.cn.ressuscitou.Adapter

import android.content.Context
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Bundle
import android.support.v7.widget.RecyclerView
import android.support.v7.widget.RecyclerView.Adapter
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.R
import kotlinx.android.synthetic.main.song_item.view.*
import android.util.Log
import br.org.cn.ressuscitou.listener.OnInteractionOnClickListener


class CanticleAdapter(
    private val songs: List<Songs>,
    private val context: Context?,
    private val listener: OnInteractionOnClickListener?
) : Adapter<ViewHolder>(){

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
            listener?.onClick(song.id);
        })

        holder?.page.background = drawable

        var title = song.title!!.toLowerCase();
        holder?.title.text = title.capitalize();

        if(song.url.equals("X",true)){
            holder?.downloadImage.visibility= View.VISIBLE
        }else{
            holder?.downloadImage.visibility= View.GONE;
        }

        Log.d("HAS_AUDIO", song.hasaudio.toString());

        if(song.hasaudio){
            holder?.downloadImage.setImageDrawable(context!!.resources.getDrawable(R.drawable.download_on))
        }
    }

    fun colorsByCategory(category:Int): String {
        val colors = arrayOf<String>("EFEFEF","6da3d1","6dd175","f2e2a0");
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
    var downloadImage = itemView.download
}