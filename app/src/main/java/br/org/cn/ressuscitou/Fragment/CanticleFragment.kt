package br.org.cn.ressuscitou.Fragment

import android.os.Bundle
import android.support.v4.app.Fragment
import android.util.Log
import br.org.cn.ressuscitou.Persistence.Entities.Songs

import kotlinx.android.synthetic.main.fragment_canticle.view.*
import android.support.v7.widget.RecyclerView
import android.widget.TextView
import br.org.cn.ressuscitou.R
import android.view.*

import android.graphics.Color
import android.support.v7.widget.SearchView
import android.widget.EditText
import br.org.cn.ressuscitou.AsyncTask.CanticleTask
import br.org.cn.ressuscitou.Auxiliar.Filter
import br.org.cn.ressuscitou.Utils.Common

// TODO: Rename parameter arguments, choose names that match
private const val TYPEQUERY = "CATEGORY"

class CanticleFragment : Fragment() {

    //DATA ON VIEW
    private var categorySong: String? = null
    var col: String? = null;
    var termStr: String? = null;

    //ELEMENTS ON VIEW
    var not_result: TextView? = null;
    var recyclerView: RecyclerView? = null;

    var songs: List<Songs>;

    init {
        songs = ArrayList<Songs>()
    }


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            categorySong = it.getString(TYPEQUERY)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        var view = inflater.inflate(R.layout.fragment_canticle, container, false)
        setHasOptionsMenu(true);
        recyclerView = view.song_list
        not_result = view.not_results;

        Log.i("VIEW", "onCreateView");
        return view;
    }

    override fun onCreateOptionsMenu(menu: Menu?, inflater: MenuInflater?) {
        inflater!!.inflate(R.menu.main, menu)

        var comon = Common()

        val item = menu!!.findItem(R.id.action_search)
        val searchViewT = item!!.getActionView() as SearchView
        searchViewT.setBackgroundResource(R.drawable.corner_searchview)
        searchViewT.minimumHeight = 10

        val editText = searchViewT.findViewById<EditText>(android.support.v7.appcompat.R.id.search_src_text)
        editText.setTextColor(Color.BLACK)


        searchViewT.setOnQueryTextListener(object : SearchView.OnQueryTextListener {
            override fun onQueryTextSubmit(term: String?): Boolean {
                termStr = comon.unaccent(term.toString(), true)
                songs(termStr.toString(), col);
                return true;
            }

            override fun onQueryTextChange(term: String?): Boolean {
                termStr = comon.unaccent(term.toString(), true)
                songs(termStr.toString(), col);
                return true;
            }
        })
    }


    override fun onActivityCreated(savedInstanceState: Bundle?) {
        super.onActivityCreated(savedInstanceState)
        println(col);
        songs(termStr.toString(), col);
    }

    private fun songs(term: String?, ligurgic: String?) {
        var task = CanticleTask(this, recyclerView!!, not_result);

        Log.d("here", "testando")

        var filter = Filter()
        filter.term = term
        filter.liturgic = ligurgic
        filter.category = categorySong



        task.execute(filter);

    }

    companion object {

        @JvmStatic
        fun newInstance(categorySong: String?) =
            CanticleFragment().apply {
                arguments = Bundle().apply {
                    putString(TYPEQUERY, categorySong.toString());
                }
            }
    }
}
