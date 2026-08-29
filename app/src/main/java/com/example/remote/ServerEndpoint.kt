package com.example.remote

import android.content.Context
import android.util.Base64
import com.example.BuildConfig
import okhttp3.HttpUrl.Companion.toHttpUrlOrNull

/**
 * Runtime-selected ChatNU instance.
 *
 * Normal public instances rely on the Android system trust store. During a real Internet blackout,
 * a self-hosted instance can instead provide an emergency enrollment URL with a pinned local CA:
 *
 * https://chat.lan#chatnu-ca=sha256/<base64-spki-sha256>
 *
 * The fragment never goes to the server. It only tells ChatNU which emergency CA key is allowed for
 * this origin, avoiding dangerous global "trust all certificates" behavior.
 */
object ServerEndpoint {
    private const val PREFS_NAME = "chatnu_server"
    private const val KEY_API_URL = "api_url"
    private const val KEY_TLS_CA_PIN = "tls_ca_pin"
    private const val PIN_FRAGMENT_PREFIX = "chatnu-ca="

    @Volatile
    private var selectedApiUrl: String = BuildConfig.CHATNU_API_URL

    @Volatile
    private var selectedTlsCaPin: String? = null

    fun initialize(context: Context) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val stored = prefs.getString(KEY_API_URL, null)
        selectedApiUrl = normalizeUrl(stored ?: BuildConfig.CHATNU_API_URL)
            .getOrElse { BuildConfig.CHATNU_API_URL }
        selectedTlsCaPin = prefs.getString(KEY_TLS_CA_PIN, null)?.takeIf(::isValidPin)
    }

    fun apiUrl(): String = selectedApiUrl

    /** null means use the normal Android system CA store. */
    fun tlsCaPin(): String? = selectedTlsCaPin

    fun isEmergencyTls(): Boolean = selectedTlsCaPin != null

    /** Safe to display/copy: the fragment is local client enrollment data and is never sent in HTTP. */
    fun enrollmentValue(): String = selectedTlsCaPin?.let { "$selectedApiUrl#$PIN_FRAGMENT_PREFIX$it" }
        ?: selectedApiUrl

    fun hostLabel(): String = selectedApiUrl.toHttpUrlOrNull()?.let { url ->
        val base = if (url.port == url.defaultPort()) url.host else "${url.host}:${url.port}"
        if (isEmergencyTls()) "$base · pinned" else base
    } ?: selectedApiUrl

    /**
     * E2EE identity belongs to the ChatNU origin, not to its current transport certificate.
     * Switching the same origin between public-CA and emergency-pinned TLS must not rotate the
     * Android Keystore identity or make old message history undecryptable.
     */
    fun identityNamespace(): String = selectedApiUrl.toHttpUrlOrNull()?.let { url ->
        "${url.scheme}://${url.host}:${url.port}"
    } ?: selectedApiUrl

    fun configure(context: Context, rawValue: String): Result<String> {
        return parseEnrollment(rawValue).map { enrollment ->
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().apply {
                putString(KEY_API_URL, enrollment.url)
                if (enrollment.caPin == null) remove(KEY_TLS_CA_PIN)
                else putString(KEY_TLS_CA_PIN, enrollment.caPin)
            }.apply()
            selectedApiUrl = enrollment.url
            selectedTlsCaPin = enrollment.caPin
            enrollment.url
        }
    }

    fun reset(context: Context) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .remove(KEY_API_URL)
            .remove(KEY_TLS_CA_PIN)
            .apply()
        selectedApiUrl = BuildConfig.CHATNU_API_URL
        selectedTlsCaPin = null
    }

    private fun parseEnrollment(rawValue: String): Result<Enrollment> = runCatching {
        var raw = rawValue.trim()
        require(raw.isNotBlank()) { "Server address is required." }
        if (!raw.contains("://")) raw = "https://$raw"

        val parsed = raw.toHttpUrlOrNull() ?: error("Enter a valid http(s) server address.")
        require(parsed.scheme == "https" || parsed.scheme == "http") { "Only HTTP or HTTPS servers are supported." }
        require(parsed.username.isEmpty() && parsed.password.isEmpty()) { "Server URLs cannot contain credentials." }
        require(parsed.query == null) { "Server URLs cannot contain query parameters." }
        require(parsed.encodedPath == "/" || parsed.encodedPath.isBlank()) {
            "Use the server origin only, for example https://chat.example.com"
        }

        val caPin = parsed.fragment?.let { fragment ->
            require(fragment.startsWith(PIN_FRAGMENT_PREFIX)) {
                "Unsupported URL fragment. Paste the full ChatNU emergency enrollment link."
            }
            fragment.removePrefix(PIN_FRAGMENT_PREFIX).also { pin ->
                require(isValidPin(pin)) { "Invalid ChatNU emergency CA pin." }
            }
        }
        if (caPin != null) {
            require(parsed.scheme == "https") { "Emergency pinned enrollment requires HTTPS." }
        }

        val normalized = parsed.newBuilder()
            .encodedPath("/")
            .query(null)
            .fragment(null)
            .build()
            .toString()

        Enrollment(normalized, caPin)
    }

    private fun normalizeUrl(rawValue: String): Result<String> = runCatching {
        var raw = rawValue.trim()
        if (!raw.contains("://")) raw = "https://$raw"
        val url = raw.toHttpUrlOrNull() ?: error("Invalid stored URL")
        require(url.scheme == "https" || url.scheme == "http")
        url.newBuilder().encodedPath("/").query(null).fragment(null).build().toString()
    }

    private fun isValidPin(value: String): Boolean {
        if (!value.startsWith("sha256/")) return false
        val encoded = value.removePrefix("sha256/")
        return runCatching { Base64.decode(encoded, Base64.DEFAULT).size == 32 }.getOrDefault(false)
    }

    private data class Enrollment(val url: String, val caPin: String?)
}

private fun okhttp3.HttpUrl.defaultPort(): Int = when (scheme) {
    "https" -> 443
    else -> 80
}
