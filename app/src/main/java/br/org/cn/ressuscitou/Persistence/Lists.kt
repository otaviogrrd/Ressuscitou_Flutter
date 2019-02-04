package br.org.cn.ressuscitou.Persistence

import com.j256.ormlite.field.DatabaseField
import com.j256.ormlite.table.DatabaseTable
import java.sql.Date

@DatabaseTable
class Lists {
    @DatabaseField(generatedId = true)
    var id: Int = 0;

    @DatabaseField
    var title: String ? = null

    @DatabaseField
    var songs: List<Songs> ? = null

    @DatabaseField
    var date: Date? = null;

    constructor()


    constructor(title: String?, songs: List<Songs>?, date: Date?){
        this.title = title
        this.songs = songs
        this.date = date
    }

}