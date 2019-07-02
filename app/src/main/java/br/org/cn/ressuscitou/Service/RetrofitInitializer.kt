package br.org.cn.ressuscitou.Service

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import com.google.gson.GsonBuilder
import com.google.gson.Gson
import org.jetbrains.anko.custom.async


class RetrofitInitializer {
    var gson = GsonBuilder()
        .setLenient()
        .create()

        val retrofit = Retrofit.Builder()
        .baseUrl("https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/")
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()

        fun ressucitouApp() : SongService{
            return retrofit.create(SongService::class.java)
        }
}