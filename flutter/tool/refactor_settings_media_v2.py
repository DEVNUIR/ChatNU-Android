from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]


def replace_once(path: Path, old: str, new: str) -> None:
    text = path.read_text()
    if old not in text:
        raise SystemExit(f"Expected source block not found in {path}: {old[:90]!r}")
    path.write_text(text.replace(old, new, 1))


# ---- Flutter API client: profile writes + public avatar URL normalization ----
api = ROOT / "flutter/lib/core/network/chatnu_api_client.dart"
replace_once(
    api,
    """    return AuthResponse.fromJson(json);\n  }\n\n  Future<AuthResponse> login({""",
    """    return _authResponse(json);\n  }\n\n  Future<AuthResponse> login({""",
)
replace_once(
    api,
    """    return AuthResponse.fromJson(json);\n  }\n\n  Future<void> recover({""",
    """    return _authResponse(json);\n  }\n\n  Future<void> recover({""",
)
replace_once(
    api,
    """  Future<UserDto> me() async {\n    final json = await _getJson('me');\n    final value = json['user'];\n    return UserDto.fromJson(value is Map ? _map(value) : json);\n  }\n\n  Future<void> updateIdentityKey(String identityPublicKey) async {""",
    """  Future<UserDto> me() async {\n    final json = await _getJson('me');\n    final value = json['user'];\n    return _normalizeUser(UserDto.fromJson(value is Map ? _map(value) : json));\n  }\n\n  Future<UserDto> updateProfile({\n    required String displayName,\n    required String? bio,\n  }) async {\n    final json = await _patchJson('me', <String, dynamic>{\n      'displayName': displayName,\n      'bio': bio,\n    });\n    return _normalizeUser(UserDto.fromJson(_map(json['user'])));\n  }\n\n  Future<UserDto> uploadAvatar({\n    required Uint8List bytes,\n    required String fileName,\n  }) async {\n    _ensureTransportAllowed();\n    try {\n      final response = await _dio.post<dynamic>(\n        'me/avatar',\n        data: FormData.fromMap(<String, dynamic>{\n          'file': MultipartFile.fromBytes(bytes, filename: fileName),\n        }),\n      );\n      final json = _map(response.data);\n      return _normalizeUser(UserDto.fromJson(_map(json['user'])));\n    } on DioException catch (error) {\n      throw _apiException(error);\n    }\n  }\n\n  Future<UserDto> removeAvatar() async {\n    final json = await _deleteJson('me/avatar');\n    return _normalizeUser(UserDto.fromJson(_map(json['user'])));\n  }\n\n  Future<void> updateIdentityKey(String identityPublicKey) async {""",
)
replace_once(
    api,
    """    return _list(\n      json['users'],\n    ).map((item) => UserDto.fromJson(_map(item))).toList(growable: false);""",
    """    return _list(json['users'])\n        .map((item) => _normalizeUser(UserDto.fromJson(_map(item))))\n        .toList(growable: false);""",
)
replace_once(
    api,
    """    return _list(json['conversations'])\n        .map((item) => ConversationDto.fromJson(_map(item)))\n        .toList(growable: false);""",
    """    return _list(json['conversations'])\n        .map((item) => _normalizeConversation(ConversationDto.fromJson(_map(item))))\n        .toList(growable: false);""",
)
replace_once(
    api,
    """    return ConversationDto.fromJson(_map(json['conversation']));\n  }\n\n  Future<ConversationDto> createGroup({""",
    """    return _normalizeConversation(\n      ConversationDto.fromJson(_map(json['conversation'])),\n    );\n  }\n\n  Future<ConversationDto> createGroup({""",
)
replace_once(
    api,
    """    return ConversationDto.fromJson(_map(json['conversation']));\n  }\n\n  Future<void> updateConversationPreferences(""",
    """    return _normalizeConversation(\n      ConversationDto.fromJson(_map(json['conversation'])),\n    );\n  }\n\n  Future<void> updateConversationPreferences(""",
)
replace_once(
    api,
    """  Future<String?> _refreshAccessToken() {""",
    """  Future<Map<String, dynamic>> _deleteJson(String path) async {\n    _ensureTransportAllowed();\n    try {\n      final response = await _dio.delete<dynamic>(path);\n      final body = response.data;\n      return body is Map ? _map(body) : <String, dynamic>{};\n    } on DioException catch (error) {\n      throw _apiException(error);\n    }\n  }\n\n  Future<String?> _refreshAccessToken() {""",
)
replace_once(
    api,
    """  void _ensureTransportAllowed() {""",
    """  AuthResponse _authResponse(Map<String, dynamic> json) {\n    final response = AuthResponse.fromJson(json);\n    return AuthResponse(\n      user: _normalizeUser(response.user),\n      deviceId: response.deviceId,\n      accessToken: response.accessToken,\n      refreshToken: response.refreshToken,\n      expiresIn: response.expiresIn,\n      recoveryCode: response.recoveryCode,\n    );\n  }\n\n  UserDto _normalizeUser(UserDto user) => UserDto(\n    id: user.id,\n    username: user.username,\n    displayName: user.displayName,\n    avatarUrl: _normalizePublicUrl(user.avatarUrl),\n    bio: user.bio,\n    lastSeenAt: user.lastSeenAt,\n  );\n\n  ConversationDto _normalizeConversation(ConversationDto dto) => ConversationDto(\n    id: dto.id,\n    type: dto.type,\n    title: dto.title,\n    avatarUrl: _normalizePublicUrl(dto.avatarUrl),\n    members: dto.members.map(_normalizeUser).toList(growable: false),\n    isPinned: dto.isPinned,\n    isMuted: dto.isMuted,\n    unreadCount: dto.unreadCount,\n    updatedAt: dto.updatedAt,\n    lastMessage: dto.lastMessage,\n  );\n\n  String? _normalizePublicUrl(String? value) {\n    final raw = value?.trim();\n    if (raw == null || raw.isEmpty) return null;\n    final parsed = Uri.tryParse(raw);\n    if (parsed != null && parsed.hasScheme) return parsed.toString();\n    return _endpoint.restUri.resolve(raw).toString();\n  }\n\n  void _ensureTransportAllowed() {""",
)


# ---- Session controller: real profile edit/avatar + safe server switching ----
session = ROOT / "flutter/lib/features/auth/application/session_controller.dart"
replace_once(session, "import 'dart:io';\n", "import 'dart:io';\nimport 'dart:typed_data';\n")
replace_once(
    session,
    "import 'package:chatnu/core/di/app_providers.dart';\n",
    "import 'package:chatnu/core/config/server_endpoint.dart';\nimport 'package:chatnu/core/di/app_providers.dart';\n",
)
replace_once(
    session,
    """  Future<void> logout() async {""",
    """  Future<String?> updateProfile({\n    required String displayName,\n    required String? bio,\n  }) async {\n    final cleanName = displayName.trim();\n    final cleanBio = bio?.trim();\n    if (cleanName.isEmpty || cleanName.length > 80) {\n      return 'Display name must be between 1 and 80 characters.';\n    }\n    if ((cleanBio?.length ?? 0) > 160) {\n      return 'Bio must be 160 characters or fewer.';\n    }\n    try {\n      final user = await ref.read(apiClientProvider).updateProfile(\n        displayName: cleanName,\n        bio: cleanBio?.isEmpty == true ? null : cleanBio,\n      );\n      await _applyUser(user);\n      return null;\n    } on ChatNuApiException catch (error) {\n      return error.message;\n    } catch (error) {\n      return error.toString();\n    }\n  }\n\n  Future<String?> uploadAvatar({\n    required Uint8List bytes,\n    required String fileName,\n  }) async {\n    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {\n      return 'Avatar must be a non-empty image up to 5 MiB.';\n    }\n    try {\n      final user = await ref.read(apiClientProvider).uploadAvatar(\n        bytes: bytes,\n        fileName: fileName,\n      );\n      await _applyUser(user);\n      return null;\n    } on ChatNuApiException catch (error) {\n      return error.message;\n    } catch (error) {\n      return error.toString();\n    }\n  }\n\n  Future<String?> removeAvatar() async {\n    try {\n      final user = await ref.read(apiClientProvider).removeAvatar();\n      await _applyUser(user);\n      return null;\n    } on ChatNuApiException catch (error) {\n      return error.message;\n    } catch (error) {\n      return error.toString();\n    }\n  }\n\n  Future<String?> switchServer(String rawValue) async {\n    try {\n      ChatNuServerEndpoint.parse(rawValue);\n    } on FormatException catch (error) {\n      return error.message;\n    }\n    try {\n      await ref.read(apiClientProvider).logout();\n    } catch (_) {\n      // Server switching must still clear the local token if the old server is down.\n    }\n    await ref.read(credentialVaultProvider).clear();\n    try {\n      await ref.read(serverEndpointProvider.notifier).configure(rawValue);\n      state = const ChatNuSessionState.unauthenticated();\n      return null;\n    } on FormatException catch (error) {\n      return error.message;\n    } catch (error) {\n      return error.toString();\n    }\n  }\n\n  Future<String?> resetServer() async {\n    try {\n      await ref.read(apiClientProvider).logout();\n    } catch (_) {}\n    await ref.read(credentialVaultProvider).clear();\n    await ref.read(serverEndpointProvider.notifier).reset();\n    state = const ChatNuSessionState.unauthenticated();\n    return null;\n  }\n\n  Future<void> logout() async {""",
)
replace_once(
    session,
    """  Future<void> _ensureDeviceIdentity(StoredSession stored) async {""",
    """  Future<void> _applyUser(UserDto dto) async {\n    final user = ChatNuUser(\n      id: dto.id,\n      username: dto.username,\n      displayName: dto.displayName,\n      avatarUrl: dto.avatarUrl,\n      bio: dto.bio,\n    );\n    await ref.read(credentialVaultProvider).updateUser(user);\n    state = ChatNuSessionState.authenticated(user, offline: state.offline);\n  }\n\n  Future<void> _ensureDeviceIdentity(StoredSession stored) async {""",
)


# ---- Messenger controller: rich encrypted attachment metadata + static location ----
controller = ROOT / "flutter/lib/features/home/application/demo_messenger_controller.dart"
replace_once(
    controller,
    """  Future<void> sendAttachment({\n    required String conversationId,\n    required Uint8List bytes,\n    required String fileName,\n    required String mimeType,\n    required ChatNuMessageType type,\n  }) async {""",
    """  Future<void> sendAttachment({\n    required String conversationId,\n    required Uint8List bytes,\n    required String fileName,\n    required String mimeType,\n    required ChatNuMessageType type,\n    Map<String, dynamic> privateMetadata = const <String, dynamic>{},\n  }) async {""",
)
replace_once(
    controller,
    """      sizeBytes: bytes.length,\n    );""",
    """      sizeBytes: bytes.length,\n      mediaDurationMs: privateMetadata['durationMs'] is num\n          ? (privateMetadata['durationMs'] as num).toInt()\n          : null,\n      isVideoNote: privateMetadata['videoNote'] == true,\n    );""",
)
replace_once(
    controller,
    """        mimeType: mimeType,\n        type: type,\n      );""",
    """        mimeType: mimeType,\n        type: type,\n        privateMetadata: privateMetadata,\n      );""",
)
replace_once(
    controller,
    """  Future<Uint8List?> downloadAttachment(ChatNuMessage message) async {""",
    """  Future<void> sendLocation({\n    required String conversationId,\n    required double latitude,\n    required double longitude,\n  }) async {\n    final repository = _repository;\n    if (_isDemo || repository == null) return;\n    final clientId = repository.newClientId();\n    final optimistic = ChatNuMessage(\n      id: clientId,\n      clientId: clientId,\n      conversationId: conversationId,\n      senderId: state.currentUser.id,\n      senderName: state.currentUser.displayName,\n      body: 'Shared location',\n      sentAt: DateTime.now(),\n      type: ChatNuMessageType.location,\n      deliveryState: MessageDeliveryState.sending,\n      locationLatitude: latitude,\n      locationLongitude: longitude,\n    );\n    _appendMessage(optimistic);\n    _updateConversationPreview(conversationId, 'Shared location', optimistic.sentAt);\n    try {\n      final sent = await repository.sendLocation(\n        conversationId: conversationId,\n        clientId: clientId,\n        latitude: latitude,\n        longitude: longitude,\n      );\n      _replaceMessage(conversationId, clientId, sent);\n      await refreshConversations();\n    } catch (error) {\n      _replaceMessage(\n        conversationId,\n        clientId,\n        optimistic.copyWith(deliveryState: MessageDeliveryState.failed),\n      );\n      state = state.copyWith(error: _readableError(error));\n    }\n  }\n\n  Future<Uint8List?> downloadAttachment(ChatNuMessage message) async {""",
)


# ---- Server: profile edit and safe avatar upload/public serving ----
server = ROOT / "server/src/index.ts"
replace_once(
    server,
    """const upload = multer({\n  storage: multer.memoryStorage(),\n  limits: {\n    fileSize: env.MAX_UPLOAD_BYTES,\n    files: 1,\n    fields: 1,\n    parts: 3,\n    fieldNameSize: 64,\n    fieldSize: 256,\n  },\n});\n""",
    """const upload = multer({\n  storage: multer.memoryStorage(),\n  limits: {\n    fileSize: env.MAX_UPLOAD_BYTES,\n    files: 1,\n    fields: 1,\n    parts: 3,\n    fieldNameSize: 64,\n    fieldSize: 256,\n  },\n});\nconst avatarRoot = join(env.ATTACHMENT_DIR, \"avatars\");\nconst avatarUpload = multer({\n  storage: multer.memoryStorage(),\n  limits: { fileSize: 5 * 1024 * 1024, files: 1, fields: 0, parts: 1 },\n});\n""",
)
replace_once(
    server,
    """app.get(\"/me\", requireAuth, async (req: AuthedRequest, res) => {\n  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.auth!.userId } });\n  res.json({ user: publicUser(user) });\n});\n\napp.get(\"/session\"""",
    """app.get(\"/me\", requireAuth, async (req: AuthedRequest, res) => {\n  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.auth!.userId } });\n  res.json({ user: publicUser(user) });\n});\n\napp.patch(\"/me\", requireAuth, async (req: AuthedRequest, res) => {\n  const input = z\n    .object({\n      displayName: z.string().trim().min(1).max(80).optional(),\n      bio: z.string().trim().max(160).nullable().optional(),\n    })\n    .refine((value) => value.displayName !== undefined || value.bio !== undefined)\n    .parse(req.body);\n  const user = await prisma.user.update({\n    where: { id: req.auth!.userId },\n    data: input,\n  });\n  res.json({ user: publicUser(user) });\n});\n\napp.post(\"/me/avatar\", requireAuth, avatarUpload.single(\"file\"), async (req: AuthedRequest, res) => {\n  const file = req.file;\n  if (!file) return res.status(400).json({ error: \"AVATAR_REQUIRED\" });\n  const extension = file.mimetype === \"image/png\"\n    ? \"png\"\n    : file.mimetype === \"image/jpeg\"\n      ? \"jpg\"\n      : file.mimetype === \"image/webp\"\n        ? \"webp\"\n        : null;\n  if (!extension) return res.status(415).json({ error: \"UNSUPPORTED_AVATAR_TYPE\" });\n  await mkdir(avatarRoot, { recursive: true });\n  const key = `${req.auth!.userId}-${randomUUID()}.${extension}`;\n  await writeFile(join(avatarRoot, key), file.buffer);\n  const user = await prisma.user.update({\n    where: { id: req.auth!.userId },\n    data: { avatarUrl: `/avatars/${key}` },\n  });\n  res.status(201).json({ user: publicUser(user) });\n});\n\napp.delete(\"/me/avatar\", requireAuth, async (req: AuthedRequest, res) => {\n  const user = await prisma.user.update({\n    where: { id: req.auth!.userId },\n    data: { avatarUrl: null },\n  });\n  res.json({ user: publicUser(user) });\n});\n\napp.get(\"/avatars/:key\", (req, res) => {\n  const key = z.string().regex(/^[A-Za-z0-9._-]{1,220}$/).parse(req.params.key);\n  const type = key.endsWith(\".png\")\n    ? \"image/png\"\n    : key.endsWith(\".webp\")\n      ? \"image/webp\"\n      : \"image/jpeg\";\n  res.setHeader(\"Content-Type\", type);\n  res.setHeader(\"Cache-Control\", \"public, max-age=86400\");\n  const stream = createReadStream(join(avatarRoot, key));\n  stream.on(\"error\", () => {\n    if (!res.headersSent) res.status(404).end();\n    else res.destroy();\n  });\n  stream.pipe(res);\n});\n\napp.get(\"/session\"""",
)

# API contract notes for the new authenticated profile writes.
contract = ROOT / "API_CONTRACT.md"
text = contract.read_text()
anchor = "- `GET /me`"
if anchor in text and "PATCH /me" not in text:
    text = text.replace(
        anchor,
        anchor
        + "\n- `PATCH /me` — authenticated display-name/bio update; username remains immutable because it participates in the device E2EE account namespace"
        + "\n- `POST /me/avatar` — authenticated PNG/JPEG/WebP avatar upload, max 5 MiB"
        + "\n- `DELETE /me/avatar` — remove the current avatar"
        + "\n- `GET /avatars/:key` — public cacheable avatar bytes; keys are server-generated and path traversal is rejected",
        1,
    )
    contract.write_text(text)
