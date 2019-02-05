package br.org.cn.ressuscitou.Service

import retrofit2.Call
import retrofit2.http.GET

interface SongService {
    @GET("cantos_versao.txt")
    fun verifyVersion(): Call<Int>

    @GET("cantos.json")
    fun getSongs(): Call<String>;

}