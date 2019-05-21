package br.org.cn.ressuscitou.AsyncTask

import android.os.AsyncTask
import android.os.Handler
import android.util.Log
import android.view.View
import android.widget.ProgressBar
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.Service.SongService
import br.org.cn.ressuscitou.SplashActivity
import com.google.gson.JsonParser
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit

class ServiceTask(
    var activity: SplashActivity?,
    var progressBar: ProgressBar,
    var retrofit: Retrofit
) : AsyncTask<String, String, String>()
{

    var dbHelper = DataBaseHelper(activity);
    var dao = SongsDAO(dbHelper.connectionSource);

    override fun onPreExecute() {
        super.onPreExecute();
        progressBar.visibility = View.VISIBLE;
    }

    override fun doInBackground(vararg params: String?): String {
        val call = retrofit.create(SongService::class.java);

        call.getSongs().enqueue(object: Callback<String> {
            override fun onFailure(call: Call<String>, t: Throwable) {
                Log.i("ERROR_R", "request not working")
            }

            override fun onResponse(call: Call<String>, response: Response<String>) {
                if(response.isSuccessful){
                    if(response.body() != null){
                        var parser = JsonParser();
                        var arr = parser.parse(response.body().toString()).asJsonArray;

                        for(item in arr){
                            var obj = item as com.google.gson.JsonObject
                            var songs = Songs()
                            songs.title = obj.get("titulo").asString;
                            songs.url = obj.get("url").asString;
                            songs.numero = obj.get("numero").asString;
                            songs.categoria = obj.get("categoria").asInt
                            songs.adve = obj.get("adve").asBoolean
                            songs.laud = obj.get("adve").asBoolean
                            songs.entr = obj.get("entr").asBoolean
                            songs.nata = obj.get("nata").asBoolean
                            songs.quar = obj.get("quar").asBoolean
                            songs.pasc = obj.get("pasc").asBoolean
                            songs.pent = obj.get("pent").asBoolean
                            songs.virg = obj.get("virg").asBoolean
                            songs.cria = obj.get("cria").asBoolean
                            songs.cpaz = obj.get("cpaz").asBoolean
                            songs.fpao = obj.get("fpao").asBoolean
                            songs.comu = obj.get("comu").asBoolean
                            songs.cfin = obj.get("cfin").asBoolean
                            songs.conteudo = obj.get("conteudo").asString
                            songs.html_base64 = obj.get("html_base64").asString
                            songs.ext_base64 = obj.get("ext_base64").asString
                            songs.hasaudio = false;

                            Log.d("SONG",obj.get("url").asString);
                            dao.create(songs);
                        }

                    }else{
                        Log.i("onEmptyResponse", "Returned empty response");
                    }
                }
            }
        })

        return "str"

    }

    override fun onPostExecute(result: String?) {
        super.onPostExecute(result)

        var handler = Handler();

        handler.postDelayed({
            if(dao.countOf() > 0){
                activity?.nextActivity();
                progressBar.visibility= View.GONE
            }
        },3000);

    }
}