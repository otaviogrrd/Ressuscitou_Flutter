package br.org.cn.ressuscitou.AsyncTask

import android.content.Intent
import android.os.AsyncTask
import android.os.Bundle
import android.support.v7.widget.LinearLayoutManager
import android.support.v7.widget.RecyclerView
import android.util.Log
import android.view.View
import android.view.animation.AnimationUtils
import android.widget.TextView
import br.org.cn.ressuscitou.Activities.CanticleDetail
import br.org.cn.ressuscitou.Adapter.CanticleAdapter
import br.org.cn.ressuscitou.Auxiliar.Filter
import br.org.cn.ressuscitou.Fragment.CanticleFragment
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.R
import br.org.cn.ressuscitou.listener.OnInteractionOnClickListener

class CanticleTask(
    var canticleFragment: CanticleFragment,
    var recyclerView: RecyclerView,
    var not_result: TextView?
) : AsyncTask<Filter, String, List<Songs>>()
{

    var dbHelper = DataBaseHelper(canticleFragment.context)
    var dao = SongsDAO(dbHelper.connectionSource)


    override fun onPreExecute() {
        super.onPreExecute()
    }

    override fun doInBackground(vararg params: Filter?): List<Songs> {

        val queryBuilder = dao.queryBuilder();
        var where = queryBuilder.where();

        where.isNotNull("title");
        queryBuilder.orderBy("title", true)

        var filterCat = when(params[0]!!.category.toString()){
            "PRE_CATECUMENATO" -> 1
            "ELEICAO" -> 2
            "CATECUMENATO" ->  3
            "LITURGIA" ->4
            else -> 0
        };

        if(filterCat > 0) {
            where.and().eq("categoria", filterCat);
        }

        if(!params[0]!!.term.isNullOrEmpty() && !params[0]!!.term.equals("null")) {
            where.and().like("conteudo", "%" + params[0]!!.term.toString().toLowerCase() + "%")
        }

        if(!params[0]!!.liturgic.isNullOrEmpty()) {
            where.and().eq(params[0]!!.liturgic, true);
        }

        Log.d("QUERY_SQL",queryBuilder.prepareStatementString())
        return queryBuilder.query();
    }

    override fun onPostExecute(result: List<Songs>?) {
        super.onPostExecute(result)

        if(!result.isNullOrEmpty()){

            not_result!!.visibility = View.GONE;

            var onInteractionOnClickListener = object : OnInteractionOnClickListener {
                override fun onClick(id: Int) {
                    var bundle = Bundle()
                    bundle.putInt("SONGID",id);

                    var intent = Intent(canticleFragment.context, CanticleDetail::class.java)

                    intent.putExtras(bundle);

                    Log.d("INTID", id.toString());

                    canticleFragment.context!!.startActivity(intent);
                }
            }

            recyclerView!!.isAnimating.and(true)
            recyclerView.layoutAnimation = AnimationUtils.loadLayoutAnimation(canticleFragment.context, R.anim.layout_animation_fall_down)
            recyclerView.removeAllViewsInLayout()
            recyclerView.layoutManager = LinearLayoutManager(canticleFragment.context)
            recyclerView.adapter = CanticleAdapter(result!!, canticleFragment.context, onInteractionOnClickListener)
            recyclerView.visibility = View.VISIBLE
            recyclerView.scheduleLayoutAnimation()



        }else{
            not_result!!.visibility = View.VISIBLE
        }
    }

}