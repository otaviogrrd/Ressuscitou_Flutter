package br.org.cn.ressuscitou.Persistence

class RawSongs{
    var id: Int = 0;
    var title: String? = null
    var html: String? = null
    var url: String? = null
    var categoria: Int = 0
    var numero: String? = null
    var adve: Boolean = false
    var laud: Boolean = false
    var entr: Boolean = false
    var nata: Boolean = false
    var quar: Boolean = false
    var pasc: Boolean = false
    var pent: Boolean = false
    var virg: Boolean = false
    var cria: Boolean = false
    var cpaz: Boolean = false
    var fpao: Boolean = false
    var comu: Boolean = false
    var cfin: Boolean = false
    var conteudo: String? = null
    var html_base64: String? = null
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