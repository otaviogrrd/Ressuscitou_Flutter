package br.org.cn.ressuscitou.AsyncTask

import android.content.Context
import android.os.AsyncTask
import android.util.Log
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import br.org.cn.ressuscitou.Fragment.SongDetail
import br.org.cn.ressuscitou.Persistence.DAO.SongsDAO
import br.org.cn.ressuscitou.Persistence.DataBaseHelper
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import br.org.cn.ressuscitou.Service.SongService
import br.org.cn.ressuscitou.Utils.Common
import com.j256.ormlite.stmt.UpdateBuilder
import okhttp3.ResponseBody
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import retrofit2.Retrofit
import retrofit2.converter.scalars.ScalarsConverterFactory
import java.io.*
import java.text.Normalizer

class AudioDownload(
    var context: Context?,
    var title: String?,
    var id: Int?,
    var fragment: SongDetail,
    var download_progress: LinearLayout?,
    var player_audio: LinearLayout?,
    var feedback_msg: TextView?
) : AsyncTask<String, String, String>()
{

    var dbHelper = DataBaseHelper(context);
    var dao = SongsDAO(dbHelper.connectionSource);

    override fun onPreExecute() {
        super.onPreExecute();
    }
    override fun doInBackground(vararg params: String?): String {
        var result = "";

        val retrofit = Retrofit.Builder()
            .baseUrl("https://github.com/otaviogrrd/Ressuscitou_Android/blob/master/audios/")
            .addConverterFactory(ScalarsConverterFactory.create())
            .build();
        val call = retrofit.create(SongService::class.java);




        val cleanTitle = Common().unaccent(title!!,false);
        val url = String.format("https://github.com/otaviogrrd/Ressuscitou_Android/blob/master/audios/%s.mp3?raw=true", cleanTitle);

        Log.d("URL_FILE", url);
        feedback_msg!!.setText("Baixando o áudio do cântico...")

        call.fetchAudio(url).enqueue(object: Callback<ResponseBody>{
            override fun onFailure(call: Call<ResponseBody>, t: Throwable) {

            }

            override fun onResponse(call: Call<ResponseBody>, response: Response<ResponseBody>) {
                if(response.isSuccessful == true){


                    val writeDisk = writeResponseBodyToDisk(response.body(), title!!.unaccent()!!.replace(" ","") + ".mp3");
                    Log.d("download", "file download was a success? $writeDisk")
                    result = "downloaded";


                    var updateBulder:UpdateBuilder<Songs, Int> = dao.updateBuilder();
                    updateBulder.updateColumnValue("hasaudio", true);
                    updateBulder.where().eq("id", id!!)
                    dao.update(updateBulder.prepare());

                    onPostExecute(result);

                }
            }

        });

        return result;
    }

    fun CharSequence.unaccent(): String {
        val REGEX_UNACCENT = "\\p{InCombiningDiacriticalMarks}+".toRegex()
        val temp = Normalizer.normalize(this, Normalizer.Form.NFD)
        return REGEX_UNACCENT.replace(temp, "")
    }



    private fun writeResponseBodyToDisk(body: ResponseBody?, fileName: String?): Boolean {
        try {
            // todo change the file location/name according to your needs

            val retrofitBetaFile = File(context!!.getExternalFilesDir(null).toString() + File.separator + fileName)


            Log.e("retrofitBetaFile", retrofitBetaFile.path)
            var inputStream: InputStream? = null
            var outputStream: OutputStream? = null

            try {
                val fileReader = ByteArray(4096)

                val fileSize = body?.contentLength()
                var fileSizeDownloaded: Long = 0

                inputStream = body?.byteStream()
                outputStream = FileOutputStream(retrofitBetaFile)

                while (true) {
                    val read = inputStream!!.read(fileReader)
                    if (read == -1) {
                        break
                    }
                    outputStream!!.write(fileReader, 0, read)
                    fileSizeDownloaded += read.toLong()
                    Log.d("writeResponseBodyToDisk", "file download: $fileSizeDownloaded of $fileSize")
                }

                outputStream!!.flush()

                return true
            } catch (e: IOException) {
                return false
            } finally {
                if (inputStream != null) {
                    inputStream!!.close()
                }

                if (outputStream != null) {
                    outputStream!!.close()
                }
            }
        } catch (e: IOException) {
            return false
        }
    }

    override fun onPostExecute(result: String?) {
        super.onPostExecute(result)

        Log.d("RESULT_DOWNLOAD", result.toString());

        if(result.toString() == "downloaded"){
            download_progress!!.visibility = View.GONE
            player_audio!!.visibility = View.VISIBLE;

            fragment.controlMediaPlayer();
        }
    }

}