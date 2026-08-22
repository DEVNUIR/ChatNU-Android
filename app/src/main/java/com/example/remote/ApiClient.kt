package com.example.remote

import com.example.BuildConfig
import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import kotlinx.coroutines.runBlocking
import okhttp3.Authenticator
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.Response
import okhttp3.Route
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory
import retrofit2.http.Body
import retrofit2.http.GET
import retrofit2.http.PATCH
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query
import java.util.concurrent.TimeUnit

interface ChatNuApi {
    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): AuthResponse

    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): AuthResponse

    @POST("auth/refresh")
    suspend fun refresh(@Body request: RefreshRequest): RefreshResponse

    @POST("auth/logout")
    suspend fun logout()

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
}

class ApiClient(private val tokenStore: TokenStore) {
    private val moshi = Moshi.Builder().addLast(KotlinJsonAdapterFactory()).build()

    private val refreshApi: ChatNuApi by lazy {
        Retrofit.Builder()
            .baseUrl(BuildConfig.CHATNU_API_URL)
            .client(OkHttpClient.Builder().callTimeout(20, TimeUnit.SECONDS).build())
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

    val httpClient: OkHttpClient = OkHttpClient.Builder()
        .addInterceptor(authInterceptor)
        .authenticator(authenticator)
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
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
}
