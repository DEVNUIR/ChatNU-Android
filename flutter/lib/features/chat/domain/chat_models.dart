enum ChatMessageRole { user, assistant }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.markdown,
    required this.timestamp,
    this.code,
    this.codeLanguage,
    this.isStreaming = false,
  });

  final String id;
  final ChatMessageRole role;
  final String markdown;
  final String timestamp;
  final String? code;
  final String? codeLanguage;
  final bool isStreaming;
}

class AiModelOption {
  const AiModelOption({
    required this.id,
    required this.name,
    required this.provider,
    required this.capability,
    required this.speedLabel,
    this.contextLabel,
  });

  final String id;
  final String name;
  final String provider;
  final String capability;
  final String speedLabel;
  final String? contextLabel;
}

const chatNuDemoModels = <AiModelOption>[
  AiModelOption(
    id: 'nova-2',
    name: 'Nova 2',
    provider: 'ChatNU',
    capability: 'Balanced reasoning',
    speedLabel: 'Fast',
    contextLabel: '128K',
  ),
  AiModelOption(
    id: 'nova-2-pro',
    name: 'Nova 2 Pro',
    provider: 'ChatNU',
    capability: 'Deep reasoning',
    speedLabel: 'Thoughtful',
    contextLabel: '256K',
  ),
  AiModelOption(
    id: 'spark',
    name: 'Spark',
    provider: 'ChatNU',
    capability: 'Quick everyday tasks',
    speedLabel: 'Very fast',
    contextLabel: '64K',
  ),
];
