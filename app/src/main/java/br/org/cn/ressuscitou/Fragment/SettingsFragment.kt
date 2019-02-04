package br.org.cn.ressuscitou.Fragment

import android.content.Context
import android.net.Uri
import android.os.Bundle
import android.support.v4.app.Fragment
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.CheckBox
import android.widget.CompoundButton
import android.widget.Toast

import br.org.cn.ressuscitou.R
import br.org.cn.ressuscitou.Utils.Preferences
import kotlinx.android.synthetic.main.fragment_settings.view.*

// TODO: Rename parameter arguments, choose names that match
// the fragment initialization parameters, e.g. ARG_ITEM_NUMBER
private const val ARG_PARAM1 = "param1"
private const val ARG_PARAM2 = "param2"

/**
 * A simple [Fragment] subclass.
 * Activities that contain this fragment must implement the
 * [Settings.OnFragmentInteractionListener] interface
 * to handle interaction events.
 * Use the [Settings.newInstance] factory method to
 * create an instance of this fragment.
 *
 */
class SettingsFragment : Fragment(), CompoundButton.OnCheckedChangeListener {


    private var param1: String? = null
    private var param2: String? = null
    var prefs: Preferences? = null;
    var EXT_MOD: Boolean? = false;

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        arguments?.let {
            param1 = it.getString(ARG_PARAM1)
            param2 = it.getString(ARG_PARAM2)
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater, container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        // Inflate the layout for this fragment

        val view = inflater.inflate(R.layout.fragment_settings, container, false);


        prefs = Preferences(context!!.applicationContext)
        EXT_MOD = prefs!!.settings_mod


        view.settings_mod.setOnCheckedChangeListener(this);
        view.settings_mod.isChecked = EXT_MOD as Boolean;

        return view
    }



    override fun onCheckedChanged(buttonView: CompoundButton?, isChecked: Boolean) {
        if(buttonView!!.id == R.id.settings_mod){

            prefs!!.settings_mod = isChecked;

        }
        }


    override fun onDetach() {
        super.onDetach()
    }


    companion object {
        /**
         * Use this factory method to create a new instance of
         * this fragment using the provided parameters.
         *
         * @param param1 Parameter 1.
         * @param param2 Parameter 2.
         * @return A new instance of fragment Settings.
         */
        // TODO: Rename and change types and number of parameters
        @JvmStatic
        fun newInstance(param1: String, param2: String) =
            SettingsFragment().apply {
                arguments = Bundle().apply {
                    putString(ARG_PARAM1, param1)
                    putString(ARG_PARAM2, param2)
                }
            }
    }
}
