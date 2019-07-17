package br.org.cn.ressuscitou.Service

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import com.google.gson.GsonBuilder


class RetrofitInitializer {
    var gson = GsonBuilder()
        .setLenient()
        .create()

        val retrofit = Retrofit.Builder()
        .baseUrl("https://raw.githubusercontent.com/otaviogrrd/Ressuscitou_Android/master/")
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()

        fun ressucitouApp() : CanticleService{
            return retrofit.create(CanticleService::class.java)
        }
}