import "dotenv/config";
import cors from "cors";
import express, { type NextFunction, type Request, type Response } from "express";
import rateLimit from "express-rate-limit";
import helmet from "helmet";
import { Redis } from "ioredis";
import { SignJWT, jwtVerify } from "jose";
import { Client as MinioClient } from "minio";
import multer from "multer";
import { Algorithm, hash, verify } from "@node-rs/argon2";
import {
  ConversationType,
  MemberRole,
  MessageType,
  Prisma,
  PrismaClient,
} from "@prisma/client";
import { createHash, randomBytes, randomUUID, timingSafeEqual } from "node:crypto";
import { createServer } from "node:http";
import { pipeline } from "node:stream/promises";
import { WebSocket, WebSocketServer } from "ws";
import { z, ZodError } from "zod";

const env = z
  .object({
    PORT: z.coerce.number().int().positive().default(3000),
    DATABASE_URL: z.string().min(1),
    REDIS_URL: z.string().default("redis://redis:6379"),
    JWT_SECRET: z.string().min(32),
    ACCESS_TOKEN_TTL_SECONDS: z.coerce.number().int().positive().default(900),
    CORS_ORIGIN: z.string().default("*"),
    MINIO_ENDPOINT: z.string().default("minio"),
    MINIO_PORT: z.coerce.number().int().positive().default(9000),
    MINIO_USE_SSL: z.enum(["true", "false"]).default("false"),
    MINIO_ACCESS_KEY: z.string().min(8),
    MINIO_SECRET_KEY: z.string().min(16),
    MINIO_BUCKET: z.string().default("chatnu-attachments"),
    MAX_UPLOAD_BYTES: z.coerce.number().int().positive().default(25 * 1024 * 1024),
  })
  .parse(process.env);

const prisma = new PrismaClient();
const redis = new Redis(env.REDIS_URL, { maxRetriesPerRequest: null });
const redisSub = redis.duplicate();
const jwtSecret = new TextEncoder().encode(env.JWT_SECRET);
const minio = new MinioClient({
  endPoint: env.MINIO_ENDPOINT,
  port: env.MINIO_PORT,
  useSSL: env.MINIO_USE_SSL === "true",
  accessKey: env.MINIO_ACCESS_KEY,
  secretKey: env.MINIO_SECRET_KEY,
});

const app = express();
const server = createServer(app);
const wss = new WebSocketServer({ noServer: true });
const upload = multer({
  storage: multer.memoryStorage(),
  limits: {
    fileSize: env.MAX_UPLOAD_BYTES,
    files: 1,
    fields: 1,
    parts: 2,
    fieldNameSize: 64,
    fieldSize: 256,
  },
});

const allowedOrigins = env.CORS_ORIGIN === "*"
  ? true
  : env.CORS_ORIGIN.split(",").map((value) => value.trim()).filter(Boolean);

app.disable("x-powered-by");
// ChatNU's Docker deployment binds the API to loopback and puts one reverse proxy in front of it.
// Trust exactly that first hop so rate limiting sees the real client address.
app.set("trust proxy", 1);
app.use(helmet());
app.use(cors({ origin: allowedOrigins, credentials: allowedOrigins !== true }));
app.use(express.json({ limit: "1mb" }));
app.use(
  rateLimit({
    windowMs: 60_000,
    limit: 180,
    standardHeaders: "draft-8",
    legacyHeaders: false,
  }),
);

const authLimiter = rateLimit({
  windowMs: 60_000,
  limit: 20,
  standardHeaders: "draft-8",
  legacyHeaders: false,
});

const usernameSchema = z
  .string()
  .trim()
  .toLowerCase()
  .min(3)
  .max(32)
  .regex(/^[a-z0-9_.]+$/);

const passwordSchema = z.string().min(10).max(200);

type AuthContext = { userId: string; deviceId: string };
type AuthedRequest = Request & { auth?: AuthContext };
type MessageWithSender = Prisma.MessageGetPayload<{ include: { sender: true } }>;

function sha256(value: string) {
  return createHash("sha256").update(value).digest("hex");
}

function constantTimeHexEqual(a: string, b: string) {
  const aa = Buffer.from(a, "hex");
  const bb = Buffer.from(b, "hex");
  return aa.length === bb.length && timingSafeEqual(aa, bb);
}

function recoveryCode() {
  const raw = randomBytes(12).toString("hex").toUpperCase();
  return raw.match(/.{1,4}/g)!.join("-");
}

async function hashSecret(value: string) {
  return hash(value, {
    algorithm: Algorithm.Argon2id,
    memoryCost: 19_456,
    timeCost: 2,
    parallelism: 1,
    outputLen: 32,
  });
}

function publicUser(user: {
  id: string;
  username: string;
  displayName: string;
  avatarUrl: string | null;
  bio: string | null;
  lastSeenAt: Date;
}) {
  return {
    id: user.id,
    username: user.username,
    displayName: user.displayName,
    avatarUrl: user.avatarUrl,
    bio: user.bio,
    lastSeenAt: user.lastSeenAt.toISOString(),
  };
}

async function signAccessToken(userId: string, deviceId: string) {
  return new SignJWT({ deviceId })
    .setProtectedHeader({ alg: "HS256" })
    .setSubject(userId)
    .setIssuedAt()
    .setExpirationTime(`${env.ACCESS_TOKEN_TTL_SECONDS}s`)
    .sign(jwtSecret);
}

async function issueSession(userId: string, deviceId: string) {
  const refreshToken = `${deviceId}.${randomBytes(48).toString("base64url")}`;
  await prisma.device.update({
    where: { id: deviceId },
    data: {
      refreshTokenHash: sha256(refreshToken),
      revokedAt: null,
      lastSeenAt: new Date(),
    },
  });
  return {
    accessToken: await signAccessToken(userId, deviceId),
    refreshToken,
    expiresIn: env.ACCESS_TOKEN_TTL_SECONDS,
  };
}

async function decodeAccessToken(token: string): Promise<AuthContext> {
  const { payload } = await jwtVerify(token, jwtSecret, { algorithms: ["HS256"] });
  if (!payload.sub || typeof payload.deviceId !== "string") throw new Error("Invalid token");
  return { userId: payload.sub, deviceId: payload.deviceId };
}

async function requireAuth(req: AuthedRequest, res: Response, next: NextFunction) {
  try {
    const header = req.header("authorization");
    if (!header?.startsWith("Bearer ")) return res.status(401).json({ error: "AUTH_REQUIRED" });
    const auth = await decodeAccessToken(header.slice(7));
    const device = await prisma.device.findUnique({ where: { id: auth.deviceId } });
    if (!device || device.userId !== auth.userId || device.revokedAt) {
      return res.status(401).json({ error: "SESSION_REVOKED" });
    }
    req.auth = auth;
    next();
  } catch {
    res.status(401).json({ error: "INVALID_TOKEN" });
  }
}

async function requireMembership(userId: string, conversationId: string) {
  return prisma.conversationMember.findUnique({
    where: { conversationId_userId: { conversationId, userId } },
  });
}

const socketsByUser = new Map<string, Set<WebSocket>>();
const socketsByDevice = new Map<string, Set<WebSocket>>();

function addSocket(map: Map<string, Set<WebSocket>>, key: string, socket: WebSocket) {
  const sockets = map.get(key) ?? new Set<WebSocket>();
  sockets.add(socket);
  map.set(key, sockets);
}

function removeSocket(map: Map<string, Set<WebSocket>>, key: string, socket: WebSocket) {
  const sockets = map.get(key);
  sockets?.delete(socket);
  if (sockets?.size === 0) map.delete(key);
}

function closeSockets(map: Map<string, Set<WebSocket>>, key: string, code = 4001, reason = "session revoked") {
  for (const socket of map.get(key) ?? []) {
    if (socket.readyState === WebSocket.OPEN || socket.readyState === WebSocket.CONNECTING) {
      socket.close(code, reason);
    }
  }
}

function deliverLocal(userId: string, payload: string) {
  const sockets = socketsByUser.get(userId);
  if (!sockets) return;
  for (const socket of sockets) {
    if (socket.readyState === WebSocket.OPEN) socket.send(payload);
  }
}

async function pushToUser(userId: string, event: unknown) {
  const payload = JSON.stringify(event);
  try {
    await redis.publish(`chatnu:user:${userId}`, payload);
  } catch {
    deliverLocal(userId, payload);
  }
}

async function pushToConversation(conversationId: string, event: unknown) {
  const members = await prisma.conversationMember.findMany({
    where: { conversationId },
    select: { userId: true },
  });
  await Promise.all(members.map((member) => pushToUser(member.userId, event)));
}

function serializeMessage(message: MessageWithSender) {
  return {
    id: message.id,
    clientId: message.clientId,
    conversationId: message.conversationId,
    senderId: message.senderId,
    senderUsername: message.sender.username,
    senderName: message.sender.displayName,
    type: message.type,
    ciphertext: message.ciphertext,
    nonce: message.nonce,
    protocolVersion: message.protocolVersion,
    metadata: message.metadata,
    createdAt: message.createdAt.toISOString(),
  };
}

app.get("/health", async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    const redisStatus = await redis.ping();
    res.json({ status: "ok", database: "ok", redis: redisStatus.toLowerCase() });
  } catch (error) {
    res.status(503).json({
      status: "degraded",
      error: error instanceof Error ? error.message : "unknown",
    });
  }
});

app.post("/auth/register", authLimiter, async (req, res) => {
  const input = z
    .object({
      username: usernameSchema,
      password: passwordSchema,
      displayName: z.string().trim().min(1).max(80),
      deviceName: z.string().trim().min(1).max(120).default("Android"),
      identityPublicKey: z.string().max(16_384).optional(),
    })
    .parse(req.body);

  const code = recoveryCode();
  const [passwordHash, recoveryCodeHash] = await Promise.all([
    hashSecret(input.password),
    hashSecret(code),
  ]);

  try {
    const result = await prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          username: input.username,
          displayName: input.displayName,
          passwordHash,
          recoveryCodeHash,
        },
      });
      const device = await tx.device.create({
        data: {
          userId: user.id,
          name: input.deviceName,
          identityPublicKey: input.identityPublicKey,
        },
      });
      return { user, device };
    });

    const session = await issueSession(result.user.id, result.device.id);
    res.status(201).json({
      user: publicUser(result.user),
      deviceId: result.device.id,
      recoveryCode: code,
      ...session,
    });
  } catch (error) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002") {
      return res.status(409).json({ error: "USERNAME_TAKEN" });
    }
    throw error;
  }
});

app.post("/auth/login", authLimiter, async (req, res) => {
  const input = z
    .object({
      username: usernameSchema,
      password: z.string().min(1).max(200),
      deviceName: z.string().trim().min(1).max(120).default("Android"),
      identityPublicKey: z.string().max(16_384).optional(),
    })
    .parse(req.body);

  const user = await prisma.user.findUnique({ where: { username: input.username } });
  if (!user || !(await verify(user.passwordHash, input.password))) {
    return res.status(401).json({ error: "INVALID_CREDENTIALS" });
  }

  const device = await prisma.device.create({
    data: {
      userId: user.id,
      name: input.deviceName,
      identityPublicKey: input.identityPublicKey,
    },
  });
  const session = await issueSession(user.id, device.id);
  await prisma.user.update({ where: { id: user.id }, data: { lastSeenAt: new Date() } });
  res.json({ user: publicUser(user), deviceId: device.id, ...session });
});

app.post("/auth/refresh", async (req, res) => {
  const { refreshToken } = z.object({ refreshToken: z.string().min(20) }).parse(req.body);
  const deviceId = refreshToken.split(".", 1)[0];
  if (!deviceId) return res.status(401).json({ error: "INVALID_REFRESH_TOKEN" });

  const device = await prisma.device.findUnique({ where: { id: deviceId } });
  if (!device?.refreshTokenHash || device.revokedAt) {
    return res.status(401).json({ error: "INVALID_REFRESH_TOKEN" });
  }

  const candidate = sha256(refreshToken);
  if (!constantTimeHexEqual(device.refreshTokenHash, candidate)) {
    return res.status(401).json({ error: "INVALID_REFRESH_TOKEN" });
  }

  res.json(await issueSession(device.userId, device.id));
});

app.post("/auth/logout", requireAuth, async (req: AuthedRequest, res) => {
  await prisma.device.update({
    where: { id: req.auth!.deviceId },
    data: { refreshTokenHash: null, revokedAt: new Date() },
  });
  closeSockets(socketsByDevice, req.auth!.deviceId);
  res.status(204).end();
});

app.post("/auth/recover", authLimiter, async (req, res) => {
  const input = z
    .object({
      username: usernameSchema,
      recoveryCode: z.string().min(8).max(80),
      newPassword: passwordSchema,
    })
    .parse(req.body);

  const user = await prisma.user.findUnique({ where: { username: input.username } });
  if (!user || !(await verify(user.recoveryCodeHash, input.recoveryCode))) {
    return res.status(401).json({ error: "INVALID_RECOVERY_CODE" });
  }

  const passwordHash = await hashSecret(input.newPassword);
  await prisma.$transaction([
    prisma.user.update({ where: { id: user.id }, data: { passwordHash } }),
    prisma.device.updateMany({
      where: { userId: user.id },
      data: { revokedAt: new Date(), refreshTokenHash: null },
    }),
  ]);
  closeSockets(socketsByUser, user.id);
  res.json({ status: "ok" });
});

app.get("/me", requireAuth, async (req: AuthedRequest, res) => {
  const user = await prisma.user.findUniqueOrThrow({ where: { id: req.auth!.userId } });
  res.json({ user: publicUser(user) });
});

app.get("/users/search", requireAuth, async (req: AuthedRequest, res) => {
  const { q } = z.object({ q: z.string().trim().min(2).max(32) }).parse(req.query);
  const users = await prisma.user.findMany({
    where: {
      id: { not: req.auth!.userId },
      OR: [
        { username: { contains: q.toLowerCase(), mode: "insensitive" } },
        { displayName: { contains: q, mode: "insensitive" } },
      ],
    },
    take: 20,
    orderBy: { username: "asc" },
  });
  res.json({ users: users.map(publicUser) });
});

app.get("/conversations", requireAuth, async (req: AuthedRequest, res) => {
  const memberships = await prisma.conversationMember.findMany({
    where: { userId: req.auth!.userId },
    include: {
      conversation: {
        include: {
          members: { include: { user: true } },
          messages: {
            where: { deletedAt: null },
            orderBy: { createdAt: "desc" },
            take: 1,
            include: { sender: true },
          },
        },
      },
    },
    orderBy: [{ isPinned: "desc" }, { conversation: { updatedAt: "desc" } }],
  });

  const conversations = await Promise.all(
    memberships.map(async (membership) => {
      const conv = membership.conversation;
      const peer = conv.type === ConversationType.DIRECT
        ? conv.members.find((member) => member.userId !== req.auth!.userId)?.user
        : undefined;
      const unreadCount = await prisma.message.count({
        where: {
          conversationId: conv.id,
          senderId: { not: req.auth!.userId },
          createdAt: { gt: membership.lastReadAt },
          deletedAt: null,
        },
      });
      const last = conv.messages[0];
      return {
        id: conv.id,
        type: conv.type,
        title: conv.type === ConversationType.DIRECT
          ? peer?.displayName ?? peer?.username ?? "Unknown"
          : conv.title ?? "Group",
        avatarUrl: conv.type === ConversationType.DIRECT ? peer?.avatarUrl ?? null : conv.avatarUrl,
        members: conv.members.map((member) => publicUser(member.user)),
        isPinned: membership.isPinned,
        isMuted: membership.isMuted,
        unreadCount,
        updatedAt: conv.updatedAt.toISOString(),
        lastMessage: last ? serializeMessage(last) : null,
      };
    }),
  );

  res.json({ conversations });
});

app.post("/conversations/direct", requireAuth, async (req: AuthedRequest, res) => {
  const { username } = z.object({ username: usernameSchema }).parse(req.body);
  const target = await prisma.user.findUnique({ where: { username } });
  if (!target || target.id === req.auth!.userId) {
    return res.status(404).json({ error: "USER_NOT_FOUND" });
  }

  const ids = [req.auth!.userId, target.id].sort();
  const directKey = `${ids[0]}:${ids[1]}`;
  let conversation = await prisma.conversation.findUnique({
    where: { directKey },
    include: { members: { include: { user: true } } },
  });

  if (!conversation) {
    try {
      conversation = await prisma.conversation.create({
        data: {
          type: ConversationType.DIRECT,
          directKey,
          createdById: req.auth!.userId,
          members: {
            create: [
              { userId: req.auth!.userId, role: MemberRole.MEMBER },
              { userId: target.id, role: MemberRole.MEMBER },
            ],
          },
        },
        include: { members: { include: { user: true } } },
      });
    } catch (error) {
      if (!(error instanceof Prisma.PrismaClientKnownRequestError) || error.code !== "P2002") {
        throw error;
      }
      conversation = await prisma.conversation.findUniqueOrThrow({
        where: { directKey },
        include: { members: { include: { user: true } } },
      });
    }
  }

  res.status(201).json({
    conversation: {
      id: conversation.id,
      type: conversation.type,
      title: target.displayName,
      avatarUrl: target.avatarUrl,
      members: conversation.members.map((member) => publicUser(member.user)),
    },
  });
});

app.post("/conversations/group", requireAuth, async (req: AuthedRequest, res) => {
  const input = z
    .object({
      title: z.string().trim().min(1).max(100),
      usernames: z.array(usernameSchema).max(99).default([]),
    })
    .parse(req.body);

  const requestedUsernames = [...new Set(input.usernames)];
  const users = requestedUsernames.length
    ? await prisma.user.findMany({ where: { username: { in: requestedUsernames } } })
    : [];
  const missing = requestedUsernames.filter((username) => !users.some((user) => user.username === username));
  if (missing.length > 0) {
    return res.status(400).json({ error: "USERS_NOT_FOUND", usernames: missing });
  }

  const memberIds = [...new Set([req.auth!.userId, ...users.map((user) => user.id)])];
  const conversation = await prisma.conversation.create({
    data: {
      type: ConversationType.GROUP,
      title: input.title,
      createdById: req.auth!.userId,
      members: {
        create: memberIds.map((userId) => ({
          userId,
          role: userId === req.auth!.userId ? MemberRole.OWNER : MemberRole.MEMBER,
        })),
      },
    },
    include: { members: { include: { user: true } } },
  });

  await pushToConversation(conversation.id, {
    type: "conversation.created",
    conversationId: conversation.id,
  });

  res.status(201).json({
    conversation: {
      id: conversation.id,
      type: conversation.type,
      title: conversation.title,
      avatarUrl: conversation.avatarUrl,
      members: conversation.members.map((member) => publicUser(member.user)),
    },
  });
});

app.patch("/conversations/:id/preferences", requireAuth, async (req: AuthedRequest, res) => {
  const conversationId = z.string().min(1).parse(req.params.id);
  const input = z
    .object({ isPinned: z.boolean().optional(), isMuted: z.boolean().optional() })
    .refine((value) => value.isPinned !== undefined || value.isMuted !== undefined)
    .parse(req.body);
  const member = await requireMembership(req.auth!.userId, conversationId);
  if (!member) return res.status(404).json({ error: "CONVERSATION_NOT_FOUND" });

  const updated = await prisma.conversationMember.update({
    where: { conversationId_userId: { conversationId, userId: req.auth!.userId } },
    data: input,
  });
  res.json({ isPinned: updated.isPinned, isMuted: updated.isMuted });
});

app.get("/conversations/:id/messages", requireAuth, async (req: AuthedRequest, res) => {
  const conversationId = z.string().min(1).parse(req.params.id);
  const member = await requireMembership(req.auth!.userId, conversationId);
  if (!member) return res.status(404).json({ error: "CONVERSATION_NOT_FOUND" });

  const query = z
    .object({
      before: z.string().datetime().optional(),
      limit: z.coerce.number().int().min(1).max(100).default(50),
    })
    .parse(req.query);

  const messages = await prisma.message.findMany({
    where: {
      conversationId,
      deletedAt: null,
      ...(query.before ? { createdAt: { lt: new Date(query.before) } } : {}),
    },
    include: { sender: true },
    orderBy: { createdAt: "desc" },
    take: query.limit,
  });
  res.json({ messages: messages.reverse().map(serializeMessage) });
});

app.post("/messages", requireAuth, async (req: AuthedRequest, res) => {
  const input = z
    .object({
      conversationId: z.string().min(1),
      clientId: z.string().max(100).default(() => randomUUID()),
      type: z.nativeEnum(MessageType).default(MessageType.TEXT),
      ciphertext: z.string().min(1).max(1_000_000),
      nonce: z.string().max(1_024).optional(),
      protocolVersion: z.string().max(100).optional(),
      metadata: z.record(z.unknown()).optional(),
    })
    .parse(req.body);

  const member = await requireMembership(req.auth!.userId, input.conversationId);
  if (!member) return res.status(404).json({ error: "CONVERSATION_NOT_FOUND" });

  const existing = await prisma.message.findFirst({
    where: { senderId: req.auth!.userId, clientId: input.clientId },
    include: { sender: true },
  });
  if (existing) return res.json({ message: serializeMessage(existing), duplicate: true });

  let message: MessageWithSender;
  try {
    message = await prisma.$transaction(async (tx) => {
      const created = await tx.message.create({
        data: {
          conversationId: input.conversationId,
          senderId: req.auth!.userId,
          clientId: input.clientId,
          type: input.type,
          ciphertext: input.ciphertext,
          nonce: input.nonce,
          protocolVersion: input.protocolVersion,
          metadata: input.metadata as Prisma.InputJsonValue | undefined,
        },
        include: { sender: true },
      });
      await tx.conversation.update({
        where: { id: input.conversationId },
        data: { updatedAt: new Date() },
      });
      return created;
    });
  } catch (error) {
    if (!(error instanceof Prisma.PrismaClientKnownRequestError) || error.code !== "P2002") {
      throw error;
    }
    message = await prisma.message.findFirstOrThrow({
      where: { senderId: req.auth!.userId, clientId: input.clientId },
      include: { sender: true },
    });
    return res.json({ message: serializeMessage(message), duplicate: true });
  }

  await pushToConversation(input.conversationId, {
    type: "message.created",
    message: serializeMessage(message),
  });
  res.status(201).json({ message: serializeMessage(message) });
});

app.post("/conversations/:id/read", requireAuth, async (req: AuthedRequest, res) => {
  const conversationId = z.string().min(1).parse(req.params.id);
  const member = await requireMembership(req.auth!.userId, conversationId);
  if (!member) return res.status(404).json({ error: "CONVERSATION_NOT_FOUND" });

  const readAt = new Date();
  await prisma.conversationMember.update({
    where: { conversationId_userId: { conversationId, userId: req.auth!.userId } },
    data: { lastReadAt: readAt },
  });
  await pushToConversation(conversationId, {
    type: "conversation.read",
    conversationId,
    userId: req.auth!.userId,
    readAt: readAt.toISOString(),
  });
  res.json({ readAt: readAt.toISOString() });
});

app.get("/sync", requireAuth, async (req: AuthedRequest, res) => {
  const query = z
    .object({
      cursor: z.string().datetime().optional(),
      limit: z.coerce.number().int().min(1).max(500).default(200),
    })
    .parse(req.query);
  const memberships = await prisma.conversationMember.findMany({
    where: { userId: req.auth!.userId },
    select: { conversationId: true },
  });
  const conversationIds = memberships.map((membership) => membership.conversationId);
  const since = query.cursor
    ? new Date(query.cursor)
    : new Date(Date.now() - 24 * 60 * 60 * 1000);

  const messages = await prisma.message.findMany({
    where: {
      conversationId: { in: conversationIds },
      createdAt: { gt: since },
      deletedAt: null,
    },
    include: { sender: true },
    orderBy: { createdAt: "asc" },
    take: query.limit,
  });
  const nextCursor = messages.at(-1)?.createdAt ?? new Date();
  res.json({
    events: messages.map((message) => ({
      type: "message.created",
      message: serializeMessage(message),
    })),
    nextCursor: nextCursor.toISOString(),
  });
});

app.post("/attachments", requireAuth, upload.single("file"), async (req: AuthedRequest, res) => {
  const conversationId = z.string().min(1).parse(req.body.conversationId);
  const member = await requireMembership(req.auth!.userId, conversationId);
  if (!member) return res.status(404).json({ error: "CONVERSATION_NOT_FOUND" });
  if (!req.file) return res.status(400).json({ error: "FILE_REQUIRED" });

  const objectKey = `${conversationId}/${Date.now()}-${randomUUID()}`;
  await minio.putObject(env.MINIO_BUCKET, objectKey, req.file.buffer, req.file.size, {
    "Content-Type": req.file.mimetype || "application/octet-stream",
  });

  const attachment = await prisma.attachment.create({
    data: {
      conversationId,
      ownerId: req.auth!.userId,
      objectKey,
      contentType: req.file.mimetype || "application/octet-stream",
      sizeBytes: req.file.size,
      fileName: req.file.originalname,
    },
  });

  res.status(201).json({
    attachment: {
      id: attachment.id,
      fileName: attachment.fileName,
      contentType: attachment.contentType,
      sizeBytes: attachment.sizeBytes,
    },
  });
});

app.get("/attachments/:id/download", requireAuth, async (req: AuthedRequest, res) => {
  const attachmentId = z.string().min(1).parse(req.params.id);
  const attachment = await prisma.attachment.findUnique({ where: { id: attachmentId } });
  if (!attachment) return res.status(404).json({ error: "ATTACHMENT_NOT_FOUND" });

  const member = await requireMembership(req.auth!.userId, attachment.conversationId);
  if (!member) return res.status(404).json({ error: "ATTACHMENT_NOT_FOUND" });

  const filename = attachment.fileName?.trim() || "attachment.bin";
  res.setHeader("Content-Type", attachment.contentType || "application/octet-stream");
  res.setHeader("Content-Length", attachment.sizeBytes.toString());
  res.setHeader("Cache-Control", "private, no-store");
  res.setHeader("Content-Disposition", `attachment; filename*=UTF-8''${encodeURIComponent(filename)}`);
  const objectStream = await minio.getObject(env.MINIO_BUCKET, attachment.objectKey);
  await pipeline(objectStream, res);
});

app.use((error: unknown, _req: Request, res: Response, _next: NextFunction) => {
  if (error instanceof ZodError) {
    return res.status(400).json({ error: "VALIDATION_ERROR", details: error.flatten() });
  }
  if (error instanceof multer.MulterError) {
    return res.status(400).json({ error: "UPLOAD_ERROR", message: error.message });
  }
  console.error(error);
  if (!res.headersSent) res.status(500).json({ error: "INTERNAL_ERROR" });
});

server.on("upgrade", async (request, socket, head) => {
  try {
    const url = new URL(request.url ?? "/", "http://localhost");
    if (url.pathname !== "/realtime") return socket.destroy();

    const header = request.headers.authorization;
    if (!header?.startsWith("Bearer ")) return socket.destroy();
    const auth = await decodeAccessToken(header.slice(7));
    const device = await prisma.device.findUnique({ where: { id: auth.deviceId } });
    if (!device || device.userId !== auth.userId || device.revokedAt) return socket.destroy();

    (request as typeof request & { auth: AuthContext }).auth = auth;
    wss.handleUpgrade(request, socket, head, (ws) => wss.emit("connection", ws, request));
  } catch {
    socket.destroy();
  }
});

wss.on("connection", (socket, request) => {
  const auth = (request as typeof request & { auth: AuthContext }).auth;
  addSocket(socketsByUser, auth.userId, socket);
  addSocket(socketsByDevice, auth.deviceId, socket);

  socket.send(JSON.stringify({
    type: "connected",
    userId: auth.userId,
    deviceId: auth.deviceId,
  }));

  socket.on("message", (raw) => {
    if (raw.toString() === "ping" && socket.readyState === WebSocket.OPEN) {
      socket.send("pong");
    }
  });

  socket.on("close", () => {
    removeSocket(socketsByUser, auth.userId, socket);
    removeSocket(socketsByDevice, auth.deviceId, socket);
  });
});

async function start() {
  const exists = await minio.bucketExists(env.MINIO_BUCKET).catch(() => false);
  if (!exists) await minio.makeBucket(env.MINIO_BUCKET);

  await redisSub.psubscribe("chatnu:user:*");
  redisSub.on("pmessage", (_pattern: string, channel: string, message: string) => {
    const userId = channel.slice("chatnu:user:".length);
    deliverLocal(userId, message);
  });

  server.listen(env.PORT, "0.0.0.0", () => {
    console.log(`ChatNU API listening on 0.0.0.0:${env.PORT}`);
  });
}

async function shutdown(signal: string) {
  console.log(`Received ${signal}, shutting down`);
  wss.clients.forEach((socket) => socket.close(1001, "server shutdown"));
  server.close();
  await Promise.allSettled([prisma.$disconnect(), redis.quit(), redisSub.quit()]);
  process.exit(0);
}

process.on("SIGTERM", () => void shutdown("SIGTERM"));
process.on("SIGINT", () => void shutdown("SIGINT"));

start().catch(async (error) => {
  console.error(error);
  await Promise.allSettled([prisma.$disconnect(), redis.quit(), redisSub.quit()]);
  process.exit(1);
});
