package br.org.cn.ressuscitou.Fragment

import android.os.Bundle
import android.support.v4.app.Fragment
import android.support.v7.widget.LinearLayoutManager
import android.util.Log
import br.org.cn.ressuscitou.Adapter.SongAdapter
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO

import kotlinx.android.synthetic.main.fragment_songs.view.*
import android.support.v7.widget.RecyclerView
import android.view.animation.AnimationUtils
import android.view.animation.LayoutAnimationController
import android.widget.TextView
import br.org.cn.ressuscitou.R
import android.view.*

import android.graphics.Color
import android.os.AsyncTask
import android.support.v7.widget.SearchView
import android.widget.EditText
import br.org.cn.ressuscitou.Auxiliar.Filter
import br.org.cn.ressuscitou.Utils.Common

// TODO: Rename parameter arguments, choose names that match
private const val TYPEQUERY = "CATEGORY"
private const val TITLE = "TITLE";


class SongsFragment : Fragment(){


    //DATA ON VIEW
    private var categorySong: String? = null
    private var title: String? = null
    var col:String? = null;
    var termStr: String? = null;

    //ELEMENTS ON VIEW
    var not_result: TextView? = null;
    var recyclerView: RecyclerView? = null;

    var songs:List<Songs>;

    init {
        songs= ArrayList<Songs>()
    }


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            categorySong = it.getString(TYPEQUERY)
            title = it.getString(TITLE)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        var view =inflater.inflate(R.layout.fragment_songs, container, false)
        setHasOptionsMenu(true);
        recyclerView = view.song_list

        not_result = view.not_results;


        return view;
    }

    override fun onCreateOptionsMenu(menu: Menu?, inflater: MenuInflater?) {
        inflater!!.inflate(R.menu.main,menu)

        var comon = Common()

        val item = menu!!.findItem(R.id.action_search)
        val searchViewT = item!!.getActionView() as SearchView
        searchViewT.setBackgroundResource(R.drawable.corner_searchview)

        val editText = searchViewT.findViewById<EditText>(android.support.v7.appcompat.R.id.search_src_text)
        editText.setTextColor(Color.BLACK)


        searchViewT.setOnQueryTextListener(object: SearchView.OnQueryTextListener{
            override fun onQueryTextSubmit(term: String?): Boolean {
                termStr = comon.unaccent(term.toString(), true)
                songs(termStr.toString(), col);
                populateRecycle(recyclerView, not_result,songs);
                return true;
            }

            override fun onQueryTextChange(term: String?): Boolean {
                termStr = comon.unaccent(term.toString(), true)
                songs(termStr.toString(), col);
                populateRecycle(recyclerView, not_result,songs);
                return true;
            }
        })
    }


    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)

        songs(termStr.toString(), col);
        populateRecycle(recyclerView, not_result, songs);
    }

    fun populateRecycle(recyclerView: RecyclerView?, not_result: TextView?, list: List<Songs>){

        recyclerView!!.isAnimating.and(true)


        val animation:LayoutAnimationController = AnimationUtils.loadLayoutAnimation(context, R.anim.layout_animation_fall_down);

        if(list.size == 0){
            not_result!!.visibility = View.VISIBLE;
        }else{
            not_result!!.visibility = View.GONE;
        }

        recyclerView.layoutAnimation = animation
        recyclerView.removeAllViewsInLayout();
        recyclerView.layoutManager = LinearLayoutManager(context);
        recyclerView.adapter = SongAdapter(list, context, fragmentManager!!);
        recyclerView.visibility = View.VISIBLE;
        recyclerView.scheduleLayoutAnimation();
    }

    private fun songs(term: String?, ligurgic: String?){

        var dbHelper = DataBaseHelper(context);
        var dao = SongsDAO(dbHelper.connectionSource);

        val queryBuilder = dao.queryBuilder();
        var where = queryBuilder.where();

        where.isNotNull("title");

        if(categorySong == "ALL"){
            queryBuilder.orderBy("id",true)
        }

        if(categorySong == "ALFABETICA") {
            queryBuilder.orderBy("title", true)
        }

        if(categorySong == "PRE_CATECUMENATO"){
            where.and().eq("categoria", 1)
        }

        if(categorySong == "ELEICAO"){
            where.and().eq("categoria", 2)
        }

        if(categorySong == "CATECUMENATO"){
            where.and().eq("categoria", 3)
        }

        if(categorySong == "LITURGIA"){
            where.and().eq("categoria", 4)

        }

        if(!term.isNullOrEmpty() && !term.equals("null")) {
            where.and().like("conteudo", "%" + term.toString().toLowerCase() + "%")
                .or()
                .like("title", "%" + term.toString().toLowerCase() + "%");
        }

        if(!ligurgic.isNullOrEmpty()) {
            where.and().eq(ligurgic, true);
        }

        Log.d("QUERY_SQL",queryBuilder.prepareStatementString())

        songs = queryBuilder.query();
    }



    companion object {


        @JvmStatic
        fun newInstance(categorySong: String?, title: String) =
            SongsFragment().apply {
                arguments = Bundle().apply {
                    putString(TYPEQUERY, categorySong.toString());
                    putString(TITLE, title);
                }
            }
    }

    class SongTask : AsyncTask<Filter, String, List<Songs>>()
    {
        override fun onPreExecute() {
            super.onPreExecute()

            var dao = SongsDAO(dbHelper.connectionSource);

            val queryBuilder = dao.queryBuilder();
            var where = queryBuilder.where();
        }

        override fun doInBackground(vararg params: Filter?): List<Songs> {
            params[0]!!.term;

        }

        override fun onPostExecute(result: List<Songs>?) {
            super.onPostExecute(result)
        }

    }
}

