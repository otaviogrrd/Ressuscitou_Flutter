package br.org.cn.ressuscitou.Utils

import java.text.Normalizer

class Common{

    fun unaccent(str: String, removeSpace: Boolean = true): String {
        val REGEX_UNACCENT = "\\p{InCombiningDiacriticalMarks}+".toRegex()
        val temp = Normalizer.normalize(str, Normalizer.Form.NFD)
        var cleanString =  REGEX_UNACCENT.replace(temp, "")
        cleanString = cleanString.replace(",","");
        cleanString = cleanString.replace("!","");

        if(removeSpace == true){
            return cleanString.replace(" ","");
        }else{
            return cleanString;
        }

    }
}