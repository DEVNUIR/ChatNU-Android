import 'package:chatnu/features/chat/domain/chat_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ChatDemoState {
  const ChatDemoState({
    required this.messages,
    required this.selectedModel,
  });

  final List<ChatMessage> messages;
  final AiModelOption selectedModel;

  ChatDemoState copyWith({
    List<ChatMessage>? messages,
    AiModelOption? selectedModel,
  }) {
    return ChatDemoState(
      messages: messages ?? this.messages,
      selectedModel: selectedModel ?? this.selectedModel,
    );
  }
}

class ChatDemoController extends Notifier<ChatDemoState> {
  @override
  ChatDemoState build() {
    return ChatDemoState(
      messages: _seedMessages,
      selectedModel: chatNuDemoModels.first,
    );
  }

  void selectModel(AiModelOption model) {
    state = state.copyWith(selectedModel: model);
  }

  void newChat() {
    state = state.copyWith(messages: <ChatMessage>[_welcomeMessage]);
  }

  void send(String rawText) {
    final text = rawText.trim();
    if (text.isEmpty) return;
    final now = DateTime.now();
    final timestamp = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    final message = ChatMessage(
      id: 'local-${now.microsecondsSinceEpoch}',
      role: ChatMessageRole.user,
      markdown: text,
      timestamp: timestamp,
    );
    state = state.copyWith(messages: <ChatMessage>[...state.messages, message]);
  }
}

final chatDemoControllerProvider =
    NotifierProvider<ChatDemoController, ChatDemoState>(ChatDemoController.new);

const _welcomeMessage = ChatMessage(
  id: 'assistant-welcome',
  role: ChatMessageRole.assistant,
  markdown:
      'Ready when you are. This is the **Phase 1 local UI shell** — no backend request will be made yet.',
  timestamp: '14:28',
);

const _seedMessages = <ChatMessage>[
  ChatMessage(
    id: 'user-1',
    role: ChatMessageRole.user,
    markdown:
        'یک مثال Flutter تمیز برای **glass composer** بده، but keep it performant on older Android phones.',
    timestamp: '14:31',
  ),
  ChatMessage(
    id: 'assistant-1',
    role: ChatMessageRole.assistant,
    markdown:
        'The trick is to treat glass as a **functional material**, not wallpaper. Keep the conversation itself mostly opaque, isolate blur to the composer/top chrome, and make the expensive path optional.\n\nبرای دستگاه‌های ضعیف‌تر، همان hierarchy را نگه می‌داریم ولی blur را کم می‌کنیم؛ ظاهر نباید ناگهان ارزان شود.',
    timestamp: '14:32',
    codeLanguage: 'dart',
    code: '''class GlassQuality {
  const GlassQuality({required this.blurSigma});

  final double blurSigma;

  static const balanced = GlassQuality(blurSigma: 8);
  static const reduced = GlassQuality(blurSigma: 0);
}''',
  ),
  ChatMessage(
    id: 'user-2',
    role: ChatMessageRole.user,
    markdown: 'Nice. Make the composer feel tactile without goofy bouncing.',
    timestamp: '14:34',
  ),
  ChatMessage(
    id: 'assistant-2',
    role: ChatMessageRole.assistant,
    markdown:
        'Use a short **press scale**, a border/highlight response, and a 180–240 ms layout transition. No ambient animation is needed. The quiet parts are what make the interaction feel premium.',
    timestamp: '14:34',
  ),
];
