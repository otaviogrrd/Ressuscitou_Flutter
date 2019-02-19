package br.org.cn.ressuscitou.Utils

import android.content.Context
import android.content.SharedPreferences

class Preferences(context: Context) {
    val PREFERENCES_FILENAME="br.org.cn.ressuscitou.prefs"
    val APP_VERSION_KEY = "version"
    val APP_SETTINGS_WIFI = "WIFI_NEWTWORK"
    val APP_SETTINGS_EXTEND_MOD = "EXTEND_MOD"
    val APP_CHIPPER_AMERICAN = "CHIPPER_AMERICAN"
    val ACCEPTED_TERMS = "ACCEPTED_TERMS"

    val prefs: SharedPreferences = context.getSharedPreferences(PREFERENCES_FILENAME, 0);

    var version: Int
        get() = prefs.getInt(APP_VERSION_KEY, 0)
        set(value) = prefs.edit().putInt(APP_VERSION_KEY, value).apply()

    var settings_mod: Boolean
        get() = prefs.getBoolean(APP_SETTINGS_EXTEND_MOD, false)
        set(value) = prefs.edit().putBoolean(APP_SETTINGS_EXTEND_MOD, value).apply()


    var settings_wifi: Boolean
        get() = prefs.getBoolean(APP_SETTINGS_WIFI, false)
        set(value) = prefs.edit().putBoolean(APP_SETTINGS_WIFI, value).apply()

    var settings_chipper: Boolean
        get() = prefs.getBoolean(APP_CHIPPER_AMERICAN, false)
        set(value) = prefs.edit().putBoolean(APP_CHIPPER_AMERICAN, value).apply()

    var accepted_terms: Boolean
        get() = prefs.getBoolean(ACCEPTED_TERMS, false)
        set(value: Boolean) = prefs.edit().putBoolean(ACCEPTED_TERMS, value).apply()


}