package br.org.cn.ressuscitou.Auxiliar

class Filter(){
    var term: String ? = null
    var liturgic: String ? = null
    var category: String ? = null

    constructor(term: String, liturgic: String, category: String) : this() {
        this.term = term;
        this.liturgic = liturgic;
        this.category = category
    }

}