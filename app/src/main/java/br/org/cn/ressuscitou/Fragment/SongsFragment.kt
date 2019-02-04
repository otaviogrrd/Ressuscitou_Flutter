package br.org.cn.ressuscitou.Fragment

import android.os.Bundle
import android.support.v4.app.Fragment
import android.support.v7.widget.LinearLayoutManager
import android.support.v7.widget.SearchView
import android.util.Log
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import br.org.cn.ressuscitou.Adapter.SongAdapter
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Songs
import br.org.cn.ressuscitou.Persistence.SongsDAO

import kotlinx.android.synthetic.main.fragment_songs.view.*
import android.support.v7.widget.RecyclerView
import android.view.animation.AnimationUtils
import android.view.animation.LayoutAnimationController
import android.widget.AdapterView
import android.widget.Spinner
import android.widget.TextView
import br.org.cn.ressuscitou.R


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
    var searchView: SearchView? = null;
    var liturgic_filter:Spinner? = null;




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

        recyclerView = view.song_list

        liturgic_filter = view.liturgic_filter;
        not_result = view.not_results;
        searchView  = view.searchView;


        return view;
    }

    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)

        searchView!!.setQueryHint("Busque um cantico");
        searchView!!.setOnQueryTextListener(object: SearchView.OnQueryTextListener{
            override fun onQueryTextSubmit(term: String?): Boolean {
                termStr = term.toString();
                songs(termStr.toString(), col);
                populateRecycle(recyclerView, not_result,songs);
                return true;
            }

            override fun onQueryTextChange(term: String?): Boolean {
                Log.d("TERM_SEARCH", term.toString());
                termStr = term.toString();
                songs(termStr.toString(), col);
                populateRecycle(recyclerView, not_result,songs);
                return true;
            }

        })

        liturgic_filter!!.onItemSelectedListener = object : AdapterView.OnItemSelectedListener{
            override fun onNothingSelected(parent: AdapterView<*>?) {
            }

            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                var col: String? = null

                if(position > 0) {
                    col = getColumnFilters(position);
                }else{
                    col = null;
                }



                songs(termStr.toString(), col);
                populateRecycle(recyclerView, not_result,songs);
            }

        }

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
        recyclerView.adapter = SongAdapter(list, context, this);
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
            where.and().like("conteudo", "%" + term.toString().toLowerCase() + "%");
        }

        if(!ligurgic.isNullOrEmpty()) {
            where.and().eq(ligurgic, true);
        }

        Log.d("QUERY_SQL",queryBuilder.prepareStatementString())

        songs = queryBuilder.query();
    }

    fun getColumnFilters(index: Int): String? {
        var response: String? = null;

        val cols = arrayOf<String>("adve","nata","quar","pasc","pent","virg","cria","laud","entr","cpaz","fpao","comu","cfin")

        if(!cols[index -1].isNullOrEmpty()){
           response = cols[index -1].toString()
        }

        return response;

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
}