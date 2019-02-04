package br.org.cn.ressuscitou.Persistence

import com.j256.ormlite.field.DatabaseField
import com.j256.ormlite.table.DatabaseTable

@DatabaseTable
class Songs{
    @DatabaseField(generatedId = true)
    var id: Int = 0;

    @DatabaseField
    var title: String? = null

    @DatabaseField
    var html: String? = null

    @DatabaseField
    var url: String? = null

    @DatabaseField
    var categoria: Int = 0

    @DatabaseField
    var numero: String? = null

    @DatabaseField
    var adve: Boolean = false

    @DatabaseField
    var laud: Boolean = false

    @DatabaseField
    var entr: Boolean = false

    @DatabaseField
    var nata: Boolean = false

    @DatabaseField
    var quar: Boolean = false

    @DatabaseField
    var pasc: Boolean = false

    @DatabaseField
    var pent: Boolean = false

    @DatabaseField
    var virg: Boolean = false

    @DatabaseField
    var cria: Boolean = false

    @DatabaseField
    var cpaz: Boolean = false

    @DatabaseField
    var fpao: Boolean = false

    @DatabaseField
    var comu: Boolean = false

    @DatabaseField
    var cfin: Boolean = false

    @DatabaseField
    var conteudo: String? = null

    @DatabaseField
    var html_base64: String? = null

    @DatabaseField
    var ext_base64: String? = null

    constructor()

    constructor(
        title: String?,
        html: String?,
        url: String?,
        categoria: Int,
        numero: String?,
        adve: Boolean,
        laud: Boolean,
        entr: Boolean,
        nata: Boolean,
        quar: Boolean,
        pasc: Boolean,
        pent: Boolean,
        virg: Boolean,
        cria: Boolean,
        cpaz: Boolean,
        fpao: Boolean,
        comu: Boolean,
        cfin: Boolean,
        conteudo: String?,
        html_base64: String?,
        ext_base64: String?
    ) {
        this.title = title
        this.html = html
        this.url = url
        this.categoria = categoria
        this.numero = numero
        this.adve = adve
        this.laud = laud
        this.entr = entr
        this.nata = nata
        this.quar = quar
        this.pasc = pasc
        this.pent = pent
        this.virg = virg
        this.cria = cria
        this.cpaz = cpaz
        this.fpao = fpao
        this.comu = comu
        this.cfin = cfin
        this.conteudo = conteudo
        this.html_base64 = html_base64
        this.ext_base64 = ext_base64
    }
}