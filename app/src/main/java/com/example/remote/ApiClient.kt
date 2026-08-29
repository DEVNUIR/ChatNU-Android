package com.example.remote

import android.util.Base64
import com.example.BuildConfig
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.Interceptor
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody
import okhttp3.Response
import okhttp3.ResponseBody
import okhttp3.Route
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.Multipart
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Part
import retrofit2.http.Path
import retrofit2.http.Query
import retrofit2.http.Streaming
import java.security.MessageDigest
import java.security.cert.CertificateException
import java.security.cert.X509Certificate
import java.util.concurrent.TimeUnit
import javax.net.ssl.SSLContext
import javax.net.ssl.TrustManagerFactory
import javax.net.ssl.X509TrustManager

interface ChatNuApi {
    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): AuthResponse

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): AuthResponse

    @POST("auth/refresh")
    suspend fun refresh(@Body request: RefreshRequest): RefreshResponse

    @POST("auth/logout")
    suspend fun logout()

    @GET("session")
    suspend fun session(): SessionResponse

    @POST("devices/identity-key")
    suspend fun updateIdentityKey(@Body request: IdentityKeyRequest): StatusResponse

    @POST("devices/push-token")
    suspend fun updatePushToken(@Body request: PushTokenRequest): StatusResponse

    @GET("users/search")
    suspend fun searchUsers(@Query("q") query: String): UsersResponse

    @GET("conversations")
    suspend fun conversations(): ConversationsResponse

    @POST("conversations/direct")
    suspend fun createDirect(@Body request: DirectConversationRequest): ConversationResponse

    @POST("conversations/group")
    suspend fun createGroup(@Body request: GroupConversationRequest): ConversationResponse

    @PATCH("conversations/{id}/preferences")
    suspend fun updatePreferences(
        @Path("id") conversationId: String,
        @Body request: ConversationPreferencesRequest
    )

    @GET("conversations/{id}/keys")
    suspend fun conversationKeys(@Path("id") conversationId: String): ConversationKeysResponse

    @GET("conversations/{id}/messages")
    suspend fun messages(
        @Path("id") conversationId: String,
        @Query("before") before: String? = null,
        @Query("limit") limit: Int = 100
    ): MessagesResponse

    @POST("messages")
    suspend fun sendMessage(@Body request: SendMessageRequest): MessageResponse

    @POST("conversations/{id}/read")
    suspend fun markRead(@Path("id") conversationId: String)

    @Multipart
    @POST("attachments")
    suspend fun uploadAttachment(
        @Part("conversationId") conversationId: RequestBody,
        @Part file: MultipartBody.Part
    ): AttachmentResponse

    @Streaming
    @GET("attachments/{id}/download")
    suspend fun downloadAttachment(@Path("id") attachmentId: String): ResponseBody

    @GET("rtc/config")
    suspend fun rtcConfig(): RtcConfigResponse

    @GET("calls/pending")
    suspend fun pendingCalls(): PendingCallsResponse
}

class ApiClient(private val tokenStore: TokenStore) {
    private val moshi = Moshi.Builder().addLast(KotlinJsonAdapterFactory()).build()
    private val trustManager = ChatNuTrustManager(systemTrustManager())
    private val sslContext = SSLContext.getInstance("TLS").apply {
        init(null, arrayOf(trustManager), null)
    }

    /**
     * Retrofit and the WebSocket code still build requests from BuildConfig placeholders.
     * This interceptor swaps only the origin at request time, preserving paths such as
     * /auth/login and /realtime. That makes one APK work with any user-selected instance.
     */
    private val serverRoutingInterceptor = Interceptor { chain ->
        val target = ServerEndpoint.apiUrl().toHttpUrl()
        val original = chain.request()
        val rewrittenUrl = original.url.newBuilder()
            .scheme(target.scheme)
            .host(target.host)
            .port(target.port)
            .build()
        chain.proceed(original.newBuilder().url(rewrittenUrl).build())
    }

    private fun baseClientBuilder(): OkHttpClient.Builder = OkHttpClient.Builder()
        .sslSocketFactory(sslContext.socketFactory, trustManager)
        .addInterceptor(serverRoutingInterceptor)

    private val refreshApi: ChatNuApi by lazy {
        Retrofit.Builder()
            .baseUrl(BuildConfig.CHATNU_API_URL)
            .client(
                baseClientBuilder()
                    .callTimeout(20, TimeUnit.SECONDS)
                    .build()
            )
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
            .create(ChatNuApi::class.java)
    }

    private val authInterceptor = Interceptor { chain ->
        val token = tokenStore.accessToken
        val original = chain.request()
        val request = if (!token.isNullOrBlank() && original.header("Authorization") == null) {
            original.newBuilder().header("Authorization", "Bearer $token").build()
        } else original
        chain.proceed(request)
    }

    private val authenticator = object : Authenticator {
        @Synchronized
        override fun authenticate(route: Route?, response: Response): Request? {
            if (responseCount(response) >= 2) return null
            val refresh = tokenStore.refreshToken ?: return null
            val usedToken = response.request.header("Authorization")?.removePrefix("Bearer ")
            val latest = tokenStore.accessToken
            if (!latest.isNullOrBlank() && latest != usedToken) {
                return response.request.newBuilder().header("Authorization", "Bearer $latest").build()
            }
            val refreshed = runCatching {
                runBlocking { refreshApi.refresh(RefreshRequest(refresh)) }
            }.getOrElse {
                tokenStore.clear()
                return null
            }
            tokenStore.accessToken = refreshed.accessToken
            tokenStore.refreshToken = refreshed.refreshToken
            return response.request.newBuilder()
                .header("Authorization", "Bearer ${refreshed.accessToken}")
                .build()
        }
    }

    val httpClient: OkHttpClient = baseClientBuilder()
        .addInterceptor(authInterceptor)
        .authenticator(authenticator)
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(60, TimeUnit.SECONDS)
        .writeTimeout(60, TimeUnit.SECONDS)
        .pingInterval(25, TimeUnit.SECONDS)
        .apply {
            if (BuildConfig.DEBUG) {
                addInterceptor(HttpLoggingInterceptor().apply { level = HttpLoggingInterceptor.Level.BASIC })
            }
        }
        .build()

    val api: ChatNuApi = Retrofit.Builder()
        .baseUrl(BuildConfig.CHATNU_API_URL)
        .client(httpClient)
        .addConverterFactory(MoshiConverterFactory.create(moshi))
        .build()
        .create(ChatNuApi::class.java)

    private fun responseCount(response: Response): Int {
        var count = 1
        var current = response.priorResponse
        while (current != null) {
            count++
            current = current.priorResponse
        }
        return count
    }

    private fun systemTrustManager(): X509TrustManager {
        val factory = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm())
        factory.init(null as java.security.KeyStore?)
        return factory.trustManagers.filterIsInstance<X509TrustManager>().firstOrNull()
            ?: error("No system X509 trust manager is available")
    }
}

/**
 * Uses the normal Android trust store unless the selected server was enrolled with ChatNU's
 * emergency CA pin. The emergency path verifies certificate validity, each signature in the chain,
 * a self-signed root, and the SHA-256 SPKI pin of that root. OkHttp still performs hostname/SAN
 * verification after this trust decision.
 */
private class ChatNuTrustManager(
    private val system: X509TrustManager
) : X509TrustManager {
    override fun checkClientTrusted(chain: Array<out X509Certificate>?, authType: String?) {
        @Suppress("UNCHECKED_CAST")
        system.checkClientTrusted(chain as Array<X509Certificate>?, authType)
    }

    override fun checkServerTrusted(chain: Array<out X509Certificate>?, authType: String?) {
        val expectedPin = ServerEndpoint.tlsCaPin()
        if (expectedPin == null) {
            @Suppress("UNCHECKED_CAST")
            system.checkServerTrusted(chain as Array<X509Certificate>?, authType)
            return
        }

        val certs = chain?.toList().orEmpty()
        if (certs.isEmpty()) throw CertificateException("Emergency TLS server did not provide a certificate chain")

        try {
            certs.forEach { it.checkValidity() }
            for (index in 0 until certs.lastIndex) {
                certs[index].verify(certs[index + 1].publicKey)
            }
            val root = certs.last()
            root.verify(root.publicKey)
            val actualPin = "sha256/" + Base64.encodeToString(
                MessageDigest.getInstance("SHA-256").digest(root.publicKey.encoded),
                Base64.NO_WRAP
            )
            if (!MessageDigest.isEqual(actualPin.toByteArray(), expectedPin.toByteArray())) {
                throw CertificateException("Emergency ChatNU CA pin does not match this server")
            }
        } catch (error: CertificateException) {
            throw error
        } catch (error: Exception) {
            throw CertificateException("Emergency ChatNU certificate verification failed", error)
        }
    }

    override fun getAcceptedIssuers(): Array<X509Certificate> = system.acceptedIssuers
}
