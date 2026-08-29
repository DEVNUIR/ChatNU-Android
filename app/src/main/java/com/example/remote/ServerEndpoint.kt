package com.example.remote

import android.content.Context
import com.example.BuildConfig
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull

/**
 * Runtime-selected ChatNU instance.
 *
 * The endpoint is intentionally not secret, so it is stored in ordinary SharedPreferences.
 * Session credentials remain inside TokenStore and are protected by Android Keystore.
 */
object ServerEndpoint {
    private const val PREFS_NAME = "chatnu_server"
    private const val KEY_API_URL = "api_url"

    @Volatile
    private var selectedApiUrl: String = BuildConfig.CHATNU_API_URL

    fun initialize(context: Context) {
        val stored = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(KEY_API_URL, null)
        selectedApiUrl = normalize(stored ?: BuildConfig.CHATNU_API_URL)
            .getOrElse { BuildConfig.CHATNU_API_URL }
    }

    fun apiUrl(): String = selectedApiUrl

    fun hostLabel(): String = selectedApiUrl.toHttpUrlOrNull()?.let { url ->
        if (url.port == url.defaultPort()) url.host else "${url.host}:${url.port}"
    } ?: selectedApiUrl

    /** Namespace cryptographic account aliases so the same username on two servers is distinct. */
    fun identityNamespace(): String = selectedApiUrl.toHttpUrlOrNull()?.let { url ->
        "${url.scheme}://${url.host}:${url.port}"
    } ?: selectedApiUrl

    fun configure(context: Context, rawValue: String): Result<String> {
        return normalize(rawValue).map { normalized ->
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_API_URL, normalized)
                .apply()
            selectedApiUrl = normalized
            normalized
        }
    }

    fun reset(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_API_URL)
            .apply()
        selectedApiUrl = BuildConfig.CHATNU_API_URL
    }

    private fun normalize(rawValue: String): Result<String> = runCatching {
        var raw = rawValue.trim()
        require(raw.isNotBlank()) { "Server address is required." }
        if (!raw.contains("://")) raw = "https://$raw"

        val url = raw.toHttpUrlOrNull() ?: error("Enter a valid http(s) server address.")
        require(url.scheme == "https" || url.scheme == "http") { "Only HTTP or HTTPS servers are supported." }
        require(url.username.isEmpty() && url.password.isEmpty()) { "Server URLs cannot contain credentials." }
        require(url.query == null && url.fragment == null) { "Server URLs cannot contain a query or fragment." }
        require(url.encodedPath == "/" || url.encodedPath.isBlank()) {
            "Use the server origin only, for example https://chat.example.com"
        }

        url.newBuilder()
            .encodedPath("/")
            .query(null)
            .fragment(null)
            .build()
            .toString()
    }
}

private fun okhttp3.HttpUrl.defaultPort(): Int = when (scheme) {
    "https" -> 443
    else -> 80
}
