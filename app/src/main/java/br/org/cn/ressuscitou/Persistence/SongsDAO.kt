package br.org.cn.ressuscitou.Persistence

import com.j256.ormlite.dao.BaseDaoImpl
import com.j256.ormlite.support.ConnectionSource

class SongsDAO : BaseDaoImpl<Songs, Int> {
    constructor(connectionSource: ConnectionSource?) : super(Songs::class.java){
        setConnectionSource(connectionSource)
        initialize()
    }
}