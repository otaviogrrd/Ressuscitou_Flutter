package br.org.cn.ressuscitou.Service

import br.org.cn.ressuscitou.Persistence.RawSongs
import br.org.cn.ressuscitou.Persistence.Songs
import okhttp3.ResponseBody
import retrofit2.Call
import retrofit2.http.GET

interface SongService {
    @GET("cantos_versao.txt")
    fun verifyVersion(): Call<Int>

    @GET("cantos.json")
    fun getSongs(): Call<String>;

}