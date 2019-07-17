package br.org.cn.ressuscitou.Service

import okhttp3.HttpUrl
import okhttp3.ResponseBody
import retrofit2.Call
import retrofit2.http.GET
import retrofit2.http.Streaming
import retrofit2.http.Url



interface CanticleService {
    @GET("cantos_versao.txt")
    fun verifyVersion(): Call<Int>

    @GET("cantos.json")
    fun getCanticles(): Call<String>;

    @GET
    @Streaming
    fun fetchAudio(@Url url: String): Call<ResponseBody>

}