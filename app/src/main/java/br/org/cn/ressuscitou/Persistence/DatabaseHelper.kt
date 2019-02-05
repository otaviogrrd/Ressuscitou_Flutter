package br.org.cn.ressuscitou.Persistence

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import br.org.cn.ressuscitou.Persistence.Entities.Songs
import com.j256.ormlite.android.apptools.OrmLiteSqliteOpenHelper
import com.j256.ormlite.support.ConnectionSource
import com.j256.ormlite.table.TableUtils

class DataBaseHelper : OrmLiteSqliteOpenHelper {

    companion object {
        private val db = "songs.db"
        private val versao = 2
    }

    constructor(context: Context?) : super(context,db,null,versao)

    override fun onCreate(database: SQLiteDatabase?, connectionSource: ConnectionSource?) {
        TableUtils.createTable(connectionSource, Songs::class.java)

    }

    override fun onUpgrade(database: SQLiteDatabase?, connectionSource: ConnectionSource?, oldVersion: Int, newVersion: Int) {}

    override fun close() {
        super.close()
    }
}
